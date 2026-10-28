import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/services/order_service.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class ModalNewRequest extends StatefulWidget {
  const ModalNewRequest({super.key});

  @override
  State<ModalNewRequest> createState() => _ModalNewRequestState();
}

class _ModalNewRequestState extends State<ModalNewRequest> {
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _targetId;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Logic: Saving the request with dynamic target assignment
  Future<void> _handleSave() async {
    final auth = context.read<AuthProvider>();
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showAlert("Atenção", "Informe a descrição do item solicitado.");
      return;
    }

    setState(() => _isLoading = true);

    // Rule: Dynamic target mapping - defaults to null (open to household) if none selected
    final String? finalTarget = _targetId == 'all' ? null : _targetId;

    try {
      await OrderService().createFamilyRequest(
        currentUserId: auth.user?.uid ?? "",
        currentUserName: auth.userProfile?['name'] ?? "Membro da Família",
        description: description,
        targetChefId: finalTarget,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showAlert("Erro", "Não foi possível enviar a solicitação.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Top Content
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Nova Solicitação",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
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
                      hint: "Ex: Arroz integral temperado ou sopa de legumes",
                      context: context,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: KinColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "O pedido ficará visível para os responsáveis pela cozinha.",
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Direcionar para:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Section 2: Target Selection Row
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'support')
                  .snapshots(),
              builder: (context, snapshot) {
                List<Widget> options = [];

                // Option: ALL (Open to any available member)
                options.add(_buildTargetBtn(
                  id: 'all',
                  label: 'Todos',
                  icon: Icons.people_outline,
                ));

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String name = (data['name'] as String? ?? "Membro").split(' ')[0];
                    options.add(_buildTargetBtn(
                      id: doc.id,
                      label: name,
                      icon: Icons.person_outline,
                    ));
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    height: 46,
                    child: Row(
                      children: [
                        _buildScrollArrow(
                          icon: Icons.chevron_left,
                          onTap: () {
                            _scrollController.animateTo(
                              _scrollController.offset - 120,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(children: options),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildScrollArrow(
                          icon: Icons.chevron_right,
                          onTap: () {
                            _scrollController.animateTo(
                              _scrollController.offset + 120,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Section 3: Bottom Content
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 24.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KinColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text(
                  "Enviar Solicitação",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetBtn({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final bool isActive = _targetId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (selected) {
          setState(() {
            _targetId = selected ? id : null;
          });
        },
        avatar: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : KinColors.primary,
        ),
        selectedColor: KinColors.primary,
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScrollArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          icon,
          size: 18,
          color: KinColors.primary,
        ),
      ),
    );
  }
}