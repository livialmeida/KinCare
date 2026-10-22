import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/services/order_service.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class ModalAddVoluntary extends StatefulWidget {
  const ModalAddVoluntary({super.key});

  @override
  State<ModalAddVoluntary> createState() => _ModalAddVoluntaryState();
}

class _ModalAddVoluntaryState extends State<ModalAddVoluntary> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isSurprise = false;

  // Logic: 'true' for Voluntary (chef proactive initiative), 'false' for Proxy (external registration)
  bool _isChefInitiative = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Logic: Proactive item insertion
  Future<void> _handleAdd() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showAlert(
        "Atenção",
        _isChefInitiative ? "Descreva o item que será preparado." : "Descreva o item solicitado.",
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final String currentUserId = auth.user?.uid ?? "";
    final String currentUserName = auth.userProfile?['name']?.toString() ?? "Chef";

    try {
      await OrderService().createVoluntaryProxyOrder(
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        description: description,
        isChefInitiative: _isChefInitiative,
        isSurprise: _isSurprise,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showAlert("Erro", "Não foi possível registrar o item.");
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),

            // Mode Selector (Chef vs Proxy)
            _buildModeSelector(),
            const SizedBox(height: 24),

            // Dynamic Description Label
            _buildLabel(_isChefInitiative ? "Item a ser preparado:" : "Item solicitado pelo membro:"),
            TextField(
              controller: _descriptionController,
              decoration: AppTheme.inputDecoration(
                hint: _isChefInitiative ? "Ex: Caldo verde congelado, torta de legumes..." : "Ex: Pão caseiro, sopa em porções...",
                context: context,
              ),
            ),
            const SizedBox(height: 20),

            // Surprise Toggle (Hidden if Proxy mode)
            if (_isChefInitiative) ...[
              _buildLabel("Visibilidade"),
              _buildSurpriseToggle(),
              const SizedBox(height: 24),
            ],

            _buildTraceabilityInfo(),
            const SizedBox(height: 24),

            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _isChefInitiative ? "Iniciativa Voluntária" : "Registro de Solicitação Manual",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildModeBtn("Preparo próprio", Icons.restaurant_outlined, _isChefInitiative, true)),
          Expanded(child: _buildModeBtn("Pedido externo", Icons.assignment_outlined, !_isChefInitiative, false)),
        ],
      ),
    );
  }

  Widget _buildModeBtn(String label, IconData icon, bool isActive, bool mode) {
    return GestureDetector(
      onTap: () => setState(() => _isChefInitiative = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? KinColors.primary : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurpriseToggle() {
    return InkWell(
      onTap: () => setState(() => _isSurprise = !_isSurprise),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isSurprise ? KinColors.primary : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isSurprise ? KinColors.primary : const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Icon(
              _isSurprise ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: _isSurprise ? Colors.white : KinColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _isSurprise ? "Item surpresa (oculto até a entrega)" : "Marcar como surpresa?",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _isSurprise ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceabilityInfo() {
    final String text = _isChefInitiative
        ? "Este registro entrará na despensa vinculado ao seu usuário como preparador."
        : "Registro manual em nome de um membro da residência.";
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleAdd,
      style: ElevatedButton.styleFrom(
        backgroundColor: KinColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(
        _isChefInitiative ? "Confirmar Preparo" : "Registrar Solicitação",
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }
}