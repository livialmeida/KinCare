import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/core/services/order_service.dart';
import 'package:kincare/core/utils/time_helper.dart';

class ModalEditOrder extends StatefulWidget {
  final String orderId;
  final String currentDescription;
  final Timestamp? createdAt;
  final String creatorId; // Security Logic: Required to validate ownership before allowing deletion
  final String currentUserId; // Security Logic: Injected to check against the creatorId

  const ModalEditOrder({
    super.key,
    required this.orderId,
    required this.currentDescription,
    required this.createdAt,
    required this.creatorId,
    required this.currentUserId,
  });

  @override
  State<ModalEditOrder> createState() => _ModalEditOrderState();
}

class _ModalEditOrderState extends State<ModalEditOrder> {
  final TextEditingController _descriptionController = TextEditingController();
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Logic: injected the current description into the text controller as the initial state
    _descriptionController.text = widget.currentDescription;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Logic: Securely update the existing document through the OrderService
  Future<void> _handleUpdate() async {
    final newDescription = _descriptionController.text.trim();
    if (newDescription.isEmpty) return;

    // Security Logic: double-check time window validity before firing database updates
    final bool isWithinTime = TimeHelper.isWithinWindow(widget.createdAt);
    if (!isWithinTime) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("O prazo para alteração desta solicitação expirou."),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _orderService.updateOrderDescription(
        orderId: widget.orderId,
        newDescription: newDescription,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Solicitação atualizada com sucesso."),
            backgroundColor: KinColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível atualizar a solicitação.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Editar Solicitação",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: AppTheme.inputDecoration(
                hint: "Atualize a descrição do item...",
                context: context,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: KinColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                "Salvar Alterações",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}