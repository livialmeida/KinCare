import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class PantryAccessButton extends StatefulWidget {
  const PantryAccessButton({super.key});

  @override
  State<PantryAccessButton> createState() => _PantryAccessButtonState();
}

class _PantryAccessButtonState extends State<PantryAccessButton> {
  bool _isLoading = false;

  // Technical: Dispatches a pantry access ticket to Firestore with caller profile data
  Future<void> _requestAccess(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final auth = context.read<AuthProvider>();
    final requesterName = auth.userProfile?['name'] ?? user.displayName ?? 'Membro';

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('pantryAccessRequests').add({
        'requesterUid': user.uid,
        'requesterName': requesterName,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        _showAlert(
          context,
          "Solicitação Enviada",
          "Seu pedido de liberação foi encaminhado para a administração. Você receberá acesso assim que aprovado.",
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showAlert(
          context,
          "Erro na Solicitação",
          "Não foi possível registrar o pedido de acesso. Verifique sua conexão e tente novamente.",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: KinColors.text)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: KinColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: _isLoading ? null : () => _requestAccess(context),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: KinColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.inventory_2_outlined, color: KinColors.primary, size: 20),
        ),
        title: const Text(
          "Solicitar Acesso à Despensa",
          style: TextStyle(fontWeight: FontWeight.w500, color: KinColors.text),
        ),
        subtitle: const Text(
          "Liberação temporária para consulta e movimentação",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: _isLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: KinColors.primary),
        )
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}