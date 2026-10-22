import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_helper.dart';
import '../../domain/stock_item.dart';

class StockCard extends StatefulWidget {
  final StockItem item;
  final VoidCallback onConsume;
  final VoidCallback? onMove;
  final Function(StockItem) onEdit;
  final bool isManagement;
  final bool hasRoutineAccess;

  const StockCard({
    super.key,
    required this.item,
    required this.onConsume,
    this.onMove,
    required this.onEdit,
    required this.isManagement,
    required this.hasRoutineAccess,
  });

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  Timer? _expirationTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  // Technical Lifecycle Sync: Recalculate countdown and force UI refresh when server token arrives
  @override
  void didUpdateWidget(covariant StockCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.createdAt != widget.item.createdAt || oldWidget.item.id != widget.item.id) {
      _expirationTimer?.cancel();
      _startCountdown();

      // Technical: Force immediate local rebuild to transition from fallback time to true server token
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    // Technical: Cancel active timer to prevent memory leaks on list scrolling/dispose
    _expirationTimer?.cancel();
    super.dispose();
  }

  // Logic: Calculate remaining window time from Core and schedule a forced UI refresh
  void _startCountdown() {
    if (widget.isManagement) return;

    final DateTime? createdAt = widget.item.createdAt;
    if (createdAt == null) return;

    final Timestamp createdAtTimestamp = Timestamp.fromDate(createdAt);
    final int remainingSeconds = TimeHelper.getRemainingSeconds(createdAtTimestamp);

    if (remainingSeconds > 0) {
      _expirationTimer = Timer(Duration(seconds: remainingSeconds), () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
      });
    } else {
      // Technical: If the item is already expired on render cycle, schedule an immediate state refresh
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final int days = item.daysRemaining;
    final bool isExpired = days < 0;
    final String location = item.location.toLowerCase();
    final String status = item.status.toLowerCase();

    Duration? thawDuration;
    if (item.thawStartedAt != null) {
      thawDuration = DateTime.now().difference(item.thawStartedAt!);
    }

    String thawInfo = "";
    if (thawDuration != null) {
      // Logic: Only show hours if it's within the first 24h of thawing
      if (thawDuration.inHours >= 0 && thawDuration.inHours < 24) {
        thawInfo = "Descongelando há ${thawDuration.inHours}h";
      } else if (thawDuration.inHours >= 24) {
        // After 24h, it just indicates it's already thawed
        thawInfo = "Item descongelado";
      }
    }

    final (Color barColor, String sideLabel) = switch (true) {
      _ when status == 'consumption' => (Colors.orangeAccent, "DESCONGELANDO"),
      _ when status == 'refrozen' => (Colors.deepPurple, "RECONGELADO"),
      _ when location.contains('freezer') => (KinColors.freezer, "FREEZER"),
      _ when location.contains('fridge') => (KinColors.fridge, "GELADEIRA"),
      _ => (const Color(0xFFE6C9A8), "DESPENSA")
    };

    final (Color statusColor, String statusText) = switch (true) {
    // 1. EXPIRED
      _ when days < 0 => (const Color(0xFFB71C1C), "Vencido há ${days.abs()} dias"),
      _ when days == 0 => (const Color(0xFFD50000), "Vence hoje • consumir imediatamente"),

    // 2. DEFROSTING / CONSUMPTION STATUS
      _ when status == 'consumption' =>
      days <= 2
          ? (const Color(0xFFD32F2F), "Descongelando • consumir em até $days dia(s)")
          : (Colors.orangeAccent, "Descongelado • $days d na geladeira"),

    // 3. REFROZEN
      _ when status == 'refrozen' => (Colors.deepPurple, "Recongelado • consumir prioritariamente ($days d)"),

    // 4. SANITARY ALERT (ANVISA)
      _ when item.wasFrozen && location.contains('fridge') && days > 5 => (const Color(0xFFE65100), "Geladeira • prazo reduzido (origem congelada)"),

    // 5. FRIDGE LOGIC
      _ when location.contains('fridge') =>
      days <= 2
          ? (const Color(0xFFD32F2F), "Geladeira • consumir em até $days dia(s)")
          : (const Color(0xFF338E3C), "Geladeira • $days dias restantes"),

    // 6. PANTRY LOGIC
      _ when location.contains('pantry') =>
      days <= 1
          ? (const Color(0xFFD32F2F), "Despensa • consumir hoje")
          : (const Color(0xFF689F38), "Despensa • $days dias restantes"),

    // 7. FREEZER GRADUAL AGING
      _ when location.contains('freezer') => switch (days) {
        <= 7 => (const Color(0xFFD50000), "Freezer • consumir em até $days dias"),
        <= 15 => (const Color(0xFFE65100), "Freezer • planejar consumo ($days d)"),
        <= 30 => (const Color(0xFFF9A825), "Freezer • consumir em breve ($days d)"),
        <= 60 => (const Color(0xFF00ACC1), "Freezer • até $days dias"),
        <= 90 => (const Color(0xFF1976D2), "Freezer • qualidade mantida ($days d)"),
        _ => (const Color(0xFF5E35B1), "Freezer • longa duração ($days d)"),
      },

    // DEFAULT CASE
      _ => (KinColors.text, "Vence em $days dias"),
    };

    // UI/UX Logic: Dynamic font weight for visual hierarchy
    final bool isBold = days <= 30 || days < 0;

    // Rule: If createdAt is null, it means Firestore server timestamp is still pending initialization.
    // In this edge case, we trust the local intent and allow editing until the true token arrives.
    final bool timeCheckPassed;
    if (item.createdAt == null) {
      timeCheckPassed = true;
    } else {
      // Technical: Pass converted timestamp directly to Core helper to avoid unused local variables
      timeCheckPassed = TimeHelper.isWithinWindow(Timestamp.fromDate(item.createdAt!));
    }

    // Consolidated permission schema for administrative actions (Bypass allows edit/delete window)
    final bool canAdminister = widget.isManagement || timeCheckPassed;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 35,
              color: barColor,
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    sideLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.description,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${item.quantity} un",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF666666)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),

                        // Technical alert: frozen origin under refrigeration
                        if (item.wasFrozen && location.contains('fridge'))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  thawInfo.isNotEmpty ? thawInfo : "Item de origem congelada",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _translateLocation(item.location),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                    if (item.authorName != null && item.authorName!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "Preparado por: ${item.authorName}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFAAAAAA),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Administrative Action Placeholder Matrix: Controlled by canAdminister
                        if (canAdminister && !isExpired) ...[
                          _buildActionButton(
                            icon: isExpired ? Icons.delete_forever : Icons.edit,
                            color: isExpired ? KinColors.danger : KinColors.primary,
                            isOutline: true,
                            onTap: () => widget.onEdit(item),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Security Boundary: Hide routine operations if support doesn't have explicity pantry authorization
                        if (widget.isManagement || widget.hasRoutineAccess) ...[
                          _buildActionButton(
                            icon: Icons.swap_vert,
                            color: KinColors.primary,
                            isOutline: true,
                            onTap: widget.onMove,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: isExpired ? Icons.delete_forever : Icons.restaurant,
                            color: isExpired ? const Color(0xFFED1C24) : const Color(0xFFFF7043),
                            isOutline: false,
                            onTap: widget.onConsume,
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI/UX Logic: Private helper for location translation (Updated for PT/EN support)
  String _translateLocation(String location) {
    final String loc = location.toLowerCase();
    if (loc.contains('freezer')) return 'Freezer';
    if (loc.contains('pantry') || loc.contains('armário') || loc.contains('armario')) return 'Despensa';
    if (loc.contains('fridge') || loc.contains('geladeira')) return 'Geladeira';
    return location;
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required bool isOutline,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isOutline ? Colors.white : color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isOutline ? color : Colors.white,
        ),
      ),
    );
  }
}