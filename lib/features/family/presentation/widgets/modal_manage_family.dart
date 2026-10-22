import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class ModalManageFamily extends StatefulWidget {
  const ModalManageFamily({super.key});

  @override
  State<ModalManageFamily> createState() => _ModalManageFamilyState();
}

class _ModalManageFamilyState extends State<ModalManageFamily> {
  // Technical: Stream mirroring subscribeToFamilyNetwork
  Stream<QuerySnapshot> _familyStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  // Logic: Approve pending user into the default support role
  Future<void> _approveUser(String targetId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(targetId).update({
        'role': 'support',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      _showAlert("Sucesso", "Acesso aprovado com sucesso.");
    } catch (e) {
      _showAlert("Erro", "Não foi possível aprovar o acesso.");
    }
  }

  // Logic: Reject and delete pending user profile record
  Future<void> _rejectUser(String targetId, String memberName) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Recusar Cadastro"),
        content: Text("Deseja realmente recusar e remover o cadastro de $memberName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('users').doc(targetId).delete();
                _showAlert("Removido", "Solicitação recusada com sucesso.");
              } catch (e) {
                _showAlert("Erro", "Não foi possível remover a solicitação.");
              }
            },
            child: const Text("Recusar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Logic: updateUserRole mirroring JS
  Future<void> _handleChangeRole(String targetId, String currentRole) async {
    final auth = context.read<AuthProvider>();
    if (!auth.canModifyUser(targetId)) {
      _showAlert("Acesso Negado", "Você não tem permissão para alterar este usuário.");
      return;
    }

    final newRole = currentRole == 'support' ? 'admin' : 'support';
    try {
      await FirebaseFirestore.instance.collection('users').doc(targetId).update({'role': newRole});
      _showAlert("Sucesso", "Nível de acesso atualizado.");
    } catch (e) {
      _showAlert("Erro", "Não foi possível atualizar o nível de acesso.");
    }
  }

  // Logic: grantTemporaryAccess mirroring JS
  Future<void> _grantAccess(String targetId, int days) async {
    final expiry = DateTime.now().add(Duration(days: days));
    await FirebaseFirestore.instance.collection('users').doc(targetId).update({
      'hasPantryAccess': true,
      'pantryAccessUntil': Timestamp.fromDate(expiry),
    });
  }

  // Logic: revokeAccess mirroring JS
  Future<void> _revokeAccess(String targetId) async {
    await FirebaseFirestore.instance.collection('users').doc(targetId).update({
      'hasPantryAccess': false,
      'pantryAccessUntil': null,
    });
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  // UI State: Sub-modal for granting access mirroring the React Modal
  void _showAccessGrantModal(Map<String, dynamic> user, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Liberar Despensa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                "Por quanto tempo ${user['name']} terá acesso?",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ...[1, 3, 7, 15].map((days) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _grantAccess(userId, days);
                    Navigator.pop(ctx);
                  },
                  child: Text("$days ${days == 1 ? 'dia' : 'dias'}", style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              )),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Gerenciar Membros", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
              ],
            ),
            const Divider(),
            Flexible(
              child: StreamBuilder<QuerySnapshot>(
                stream: _familyStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final doc = members[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildMemberCard(doc.id, data, auth);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(String id, Map<String, dynamic> data, AuthProvider auth) {
    final pantryUntil = data['pantryAccessUntil'] as Timestamp?;

    final bool isPantryEnabled = data['hasPantryAccess'] ?? false;
    final bool isDateValid = pantryUntil != null && pantryUntil.toDate().isAfter(DateTime.now());
    final bool isAccessActive = isPantryEnabled && isDateValid;

    final canIEdit = auth.canModifyUser(id);
    final String role = data['role'] ?? 'pending';
    final bool isPending = role == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFFF9E6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPending ? const Color(0xFFFFE082) : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? "Membro", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  role == 'admin'
                      ? 'Administrador'
                      : role == 'support'
                      ? 'Suporte'
                      : 'Aguardando Aprovação',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPending ? Colors.orange.shade800 : Colors.grey,
                    fontWeight: isPending ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),

                if (isAccessActive)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          "Acesso até ${DateFormat('dd/MM HH:mm').format(pantryUntil.toDate())}",
                          style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              // Pending Actions: Approve or Reject
              if (isPending && canIEdit) ...[
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                  tooltip: 'Aprovar acesso',
                  onPressed: () => _approveUser(id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Color(0xFFFF5252), size: 28),
                  tooltip: 'Recusar solicitação',
                  onPressed: () => _rejectUser(id, data['name'] ?? 'Membro'),
                ),
              ],

              // Standard Actions: Support Pantry Grant & Role Toggle
              if (!isPending) ...[
                if (role == 'support')
                  IconButton(
                    icon: Icon(
                      isAccessActive ? Icons.inventory_2 : Icons.inventory_2_outlined,
                      color: isAccessActive ? const Color(0xFF4CAF50) : KinColors.primary,
                      size: 26,
                    ),
                    tooltip: isAccessActive ? 'Revogar acesso' : 'Liberar despensa',
                    onPressed: () {
                      if (isAccessActive) {
                        _showRevokeAlert(id, data['name']);
                      } else {
                        _showAccessGrantModal(data, id);
                      }
                    },
                  ),
                if (canIEdit && id != auth.user?.uid)
                  TextButton(
                    onPressed: () => _handleChangeRole(id, role),
                    style: TextButton.styleFrom(
                      backgroundColor: KinColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("Alternar", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showRevokeAlert(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Revogar Acesso"),
        content: Text("Deseja remover o acesso de $name à despensa imediatamente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Manter acesso")),
          TextButton(
            onPressed: () {
              _revokeAccess(id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Sim, revogar"),
          ),
        ],
      ),
    );
  }
}