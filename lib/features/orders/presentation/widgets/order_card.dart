import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/core/utils/time_helper.dart';
import 'modal_edit_order.dart';

class OrderCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final String currentUid;
  final String? currentName;
  final bool isManagement;
  final VoidCallback onCheck;

  const OrderCard({
    super.key,
    required this.item,
    required this.currentUid,
    required this.currentName,
    required this.isManagement,
    required this.onCheck,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  Timer? _expirationTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _expirationTimer?.cancel();
    _startCountdown();
  }

  @override
  void dispose() {
    // Technical: Cancel the active timer to avoid memory leaks when widget disposes
    _expirationTimer?.cancel();
    super.dispose();
  }

// Logic: Calculate remaining window time from Core and schedule a forced UI refresh
  void _startCountdown() {
    if (widget.isManagement) return; // Management bypasses time rules entirely

    final Timestamp? createdAtTimestamp = widget.item['createdAt'] as Timestamp?;
    if (createdAtTimestamp == null) return;

    // Technical: Fetch exact remaining seconds directly from Core single source of truth
    final int remainingSeconds = TimeHelper.getRemainingSeconds(createdAtTimestamp);

    if (remainingSeconds > 0) {
      _expirationTimer = Timer(Duration(seconds: remainingSeconds), () {
        // Security Lifecycle Check: Ensure tree element is mounted before scheduling frame updates
        if (remainingSeconds > 0) {
          _expirationTimer = Timer(Duration(seconds: remainingSeconds), () {
            // Security Lifecycle Check: Ensure tree element is mounted before scheduling frame updates
            if (mounted) {
              setState(() {});
            }
          });
        }
      });
    }
  }

  // Logic: Duplicate alert dialog helper internal to the component scope
  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  // Logic: Re-encapsulated acceptance logic with safe async context validation
  Future<void> _handleAcceptOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'accepted',
        'authorId': widget.currentUid,
        'authorName': widget.currentName ?? "Chef",
      });

      // Security Logic: Validate if the widget is still attached to the tree after firestore async gap
      if (!mounted) return;

      _showAlert("Solicitação Assumida", "Você assumiu o preparo deste pedido.");
    } catch (e) {
      if (!mounted) return;
      _showAlert("Erro no Processamento", "Verifique as permissões de acesso.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final String status = item['status'] ?? 'pending';
    final bool isProactive = item['type'] == 'proactive';

    final Timestamp? createdAtTimestamp = item['createdAt'] as Timestamp?;

    // Technical: Fallback lookup matching data preparation logic (creatorId OR createdBy)
    final String recordCreatorId = item['creatorId'] ?? item['createdBy'] ?? "";
    final String proxyCreatorId = item['proxyCreatedById'] ?? "";

    // Security Logic: Validate real device author or proxy typist entity
    final bool isOwner = recordCreatorId == widget.currentUid || proxyCreatorId == widget.currentUid;

    // Rule: Blocks editing if the item was automatically reordered from stock consumption
    final bool isAutoReorder = item['isReorder'] == true;

    // Rule: Fetch time validation directly from Core helper
    final bool timeCheckPassed = TimeHelper.isWithinWindow(createdAtTimestamp);

    // Security Matrix: Standard requests must be pending. Proactive tasks can be edited while preparing.
    bool statusAllowsEditing = false;
    if (isProactive) {
      statusAllowsEditing = status == 'preparing';
    } else {
      statusAllowsEditing = status == 'pending';
    }

    // Consolidated permission schema for card editing
    final bool canEdit = isOwner && statusAllowsEditing && !isAutoReorder && timeCheckPassed;

    final IconData statusIcon = isProactive
        ? Icons.volunteer_activism_outlined
        : (status == 'accepted' ? Icons.check : Icons.restaurant_outlined);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: (status == 'accepted' || isProactive) ? const Border(left: BorderSide(color: Colors.green, width: 4)) : null,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (status == 'accepted' || isProactive) ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                statusIcon,
                color: (status == 'accepted' || isProactive) ? Colors.green.shade700 : Colors.black54,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['displayTitle'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  isProactive
                      ? "Iniciativa de ${item['displayCreator']}"
                      : status == 'accepted'
                      ? "Em preparo por: ${item['displayAuthor']}"
                      : "Solicitado por: ${item['displayCreator']}",
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Logic: Independent delete action for the owner (no time restricted)
          if (recordCreatorId == widget.currentUid)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
              onPressed: () async {
                final bool confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Excluir Solicitação"),
                      content: const Text("Tem certeza que deseja apagar este pedido de forma permanente?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Excluir", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ) ?? false;

                if (!confirmDelete) return;

                try {
                  await FirebaseFirestore.instance.collection('orders').doc(item['id']).delete();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pedido excluído com sucesso."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Não foi possível excluir o pedido.")),
                    );
                  }
                }
              },
            ),

          // Logic: Conditionally show edit button for valid state owners
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit, size: 22, color: KinColors.primary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ModalEditOrder(
                    orderId: item['id'],
                    currentDescription: item['description'] ?? item['item'] ?? "",
                    createdAt: item['createdAt'] as Timestamp?,
                    creatorId: item['creatorId'] ?? "", // Security Logic: Extracted from the document to validate ownership
                    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? "", // Security Logic: Current authenticated session ID
                  ),
                );
              },
            ),

          IconButton(
            icon: Icon(
              isProactive ? Icons.arrow_circle_right_outlined : (status == 'accepted' ? Icons.send : Icons.check_circle_outline),
              size: 32,
              color: (status == 'accepted' || isProactive) ? Colors.green : Colors.grey[400],
            ),
            onPressed: () {
              if (status == 'accepted' || isProactive) {
                // Technical: Temporary bypass placeholder for DeliveryModal integration mapping
                widget.onCheck();
              } else {
                _handleAcceptOrder(item['id']);
              }
            },
          ),
        ],
      ),
    );
  }
}