import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/stock_item.dart';

void showMoveStockModal(BuildContext context, StockItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _MoveStockContent(item: item),
  );
}

class _MoveStockContent extends StatefulWidget {
  final StockItem item;

  const _MoveStockContent({required this.item});

  @override
  State<_MoveStockContent> createState() => _MoveStockContentState();
}

class _MoveStockContentState extends State<_MoveStockContent> {
  int selectedQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final String currentLoc = widget.item.location.toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Mover ${widget.item.description}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),

          Text(
            "Armazenamento atual: ${widget.item.location}",
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quantidade a transferir:",
                style: TextStyle(fontSize: 16),
              ),

              Row(
                children: [
                  IconButton(
                    onPressed: selectedQuantity > 1
                        ? () => setState(() => selectedQuantity--)
                        : null,
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.orange,
                    ),
                  ),

                  Text(
                    "$selectedQuantity",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed: selectedQuantity < widget.item.quantity
                        ? () => setState(() => selectedQuantity++)
                        : null,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(),
          const SizedBox(height: 10),

          if (!currentLoc.contains('fridge'))
            _buildMoveOption(
              icon: Icons.kitchen,
              label: "Transferir para Geladeira",
              targetLocation: "fridge",
              targetStatus: widget.item.wasFrozen
                  ? 'consumption'
                  : 'in_stock',
            ),

          if (!currentLoc.contains('freezer'))
            _buildMoveOption(
              icon: Icons.ac_unit,
              label: "Transferir para Freezer",
              targetLocation: "freezer",
              targetStatus:
              (currentLoc.contains('fridge') && widget.item.wasFrozen)
                  ? 'refrozen'
                  : 'in_stock',
            ),

          if (!currentLoc.contains('pantry') &&
              !currentLoc.contains('armário'))
            _buildMoveOption(
              icon: Icons.inventory_2,
              label: "Transferir para Despensa",
              targetLocation: "pantry",
              targetStatus: 'in_stock',
            ),
        ],
      ),
    );
  }

  Widget _buildMoveOption({
    required IconData icon,
    required String label,
    required String targetLocation,
    required String targetStatus,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () => _confirmMove(targetLocation, targetStatus),
    );
  }

  void _confirmMove(String targetLocation, String targetStatus) {
    final bool goingToFreezer = targetLocation.toLowerCase().contains('freezer');

    // UI Translation Map
    const Map<String, String> locationTranslations = {
      'fridge': 'a geladeira',
      'freezer': 'o freezer',
      'pantry': 'a despensa',
    };

    final String translatedLocation = locationTranslations[targetLocation.toLowerCase()] ?? targetLocation;

    // UI Logic: Detect if this is the second (and last allowed) refreeze cycle
    final bool isLastAllowedRefreeze = goingToFreezer &&
        widget.item.wasFrozen &&
        widget.item.thawCycles == 1;

    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Confirmar movimentação"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Confirma a transferência de $selectedQuantity ${selectedQuantity > 1 ? 'unidades' : 'unidade'} para $translatedLocation?"),
            if (isLastAllowedRefreeze) ...[
              const SizedBox(height: 16),
              const Text(
                "Nota técnica: este é o último ciclo de recongelamento recomendado para assegurar integridade microbiológica e padrão sensorial.",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(confirmContext);
              _executeMove(targetLocation, targetStatus);
            },
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeMove(String targetLocation, String targetStatus) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference docRef = firestore.collection('stock').doc(widget.item.id);
    final String targetLocLower = targetLocation.toLowerCase();
    final DateTime now = DateTime.now();

    final bool goingToFreezer = targetLocLower.contains('freezer');
    final bool goingToFridge = targetLocLower.contains('fridge');
    final bool goingToPantry = targetLocLower.contains('pantry') || targetLocLower.contains('armário');

    final bool isThawing = goingToFridge && widget.item.wasFrozen;
    final bool isRefreezing = goingToFreezer && (widget.item.wasFrozen || widget.item.status == 'consumption');
    final bool newWasFrozen = goingToFreezer ? true : widget.item.wasFrozen;

    final int currentThawCycles = widget.item.thawCycles;
    final int newThawCycles = isThawing ? currentThawCycles + 1 : currentThawCycles;

    // ---------------------------------------------------------
    // 🛑 SANITARY VERIFICATIONS (Decision-based now)
    // ---------------------------------------------------------
    if (isRefreezing && currentThawCycles >= 2) {
      if (mounted) {
        final bool? proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text("Aviso Sanitário"),
              ],
            ),
            content: Text(
                "Este item já passou por $currentThawCycles ciclos de descongelamento. "
                    "Múltiplos recongelamentos elevam o risco microbiológico e alteram a textura do alimento. Deseja prosseguir?"
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("PROSSEGUIR", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        // Stops execution ONLY if the user explicitly cancels
        if (proceed != true) return;
      }
    }

    // ---------------------------------------------------------
    // 📆 EXPIRY ENGINE
    // ---------------------------------------------------------
    DateTime finalExpiry = widget.item.expiryDate;
    DateTime? originalExpiry = widget.item.originalExpiryDate;

    if (isThawing) {
      final bool isSensitive = (widget.item.daysValid != null && widget.item.daysValid! <= 30);
      final int safetyLimit = isSensitive ? 3 : 5;
      finalExpiry = now.add(Duration(days: safetyLimit));
    }
    else if (goingToFreezer) {
      if (isRefreezing && originalExpiry != null) {
        final int penaltyDays = currentThawCycles * 3;
        final int originalRemainingDays = originalExpiry.difference(now).inDays;

        if (originalRemainingDays <= 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Item com prazo original de validade atingido. Não recomendado recongelar."), backgroundColor: Colors.red),
            );
          }
          return;
        }

        finalExpiry = now.add(Duration(days: max(1, originalRemainingDays - penaltyDays)));
        if (finalExpiry.isAfter(originalExpiry)) finalExpiry = originalExpiry;
      }
      else if (widget.item.daysValid != null && widget.item.daysValid! > 0) {
        finalExpiry = now.add(Duration(days: widget.item.daysValid!));
      }
    }
    else if (goingToPantry) {
      finalExpiry = now.add(const Duration(days: 1));
    }

    // ---------------------------------------------------------
    // 💾 FIRESTORE WRITE
    // ---------------------------------------------------------
    final WriteBatch batch = firestore.batch();

    try {
      if (selectedQuantity == widget.item.quantity) {
        Map<String, dynamic> updates = {
          'location': targetLocation,
          'status': targetStatus,
          'wasFrozen': newWasFrozen,
          'expiryDate': Timestamp.fromDate(finalExpiry),
          'lastMovedAt': FieldValue.serverTimestamp(),
          'thawCycles': newThawCycles,
        };

        if (goingToFreezer) {
          updates['thawStartedAt'] = null;
          if (!widget.item.wasFrozen) updates['originalExpiryDate'] = Timestamp.fromDate(finalExpiry);
        } else if (isThawing) {
          updates['thawStartedAt'] = FieldValue.serverTimestamp();
        }

        batch.update(docRef, updates);
      }
      else {
        batch.update(docRef, {'quantity': widget.item.quantity - selectedQuantity});

        final DocumentReference newDocRef = firestore.collection('stock').doc();
        batch.set(newDocRef, {
          'description': widget.item.description,
          'quantity': selectedQuantity,
          'location': targetLocation,
          'status': targetStatus,
          'wasFrozen': newWasFrozen,
          'expiryDate': Timestamp.fromDate(finalExpiry),
          'daysValid': widget.item.daysValid,
          'lastMovedAt': FieldValue.serverTimestamp(),
          'originalExpiryDate': goingToFreezer
              ? (!widget.item.wasFrozen ? Timestamp.fromDate(finalExpiry) : widget.item.originalExpiryDate)
              : widget.item.originalExpiryDate,
          'thawCycles': newThawCycles,
          'thawStartedAt': goingToFreezer ? null : (isThawing ? FieldValue.serverTimestamp() : widget.item.thawStartedAt),
          'authorName': widget.item.authorName,
          'authorId': widget.item.authorId,
          'creatorName': widget.item.creatorName,
          'creatorId': widget.item.creatorId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("KinCare Tech Error: $e");
    }
  }
}