import 'package:flutter/material.dart';
import 'package:kincare/core/theme/app_theme.dart';

class ModalIosInstallGuide extends StatelessWidget {
  const ModalIosInstallGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // UI Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title with Icon
          const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: KinColors.primary, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Receber Alertas no iOS",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KinColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Objective explanation
          const Text(
            "Para habilitar notificações push de validade técnica e atualizações de pedidos no Safari, instale o aplicativo na Tela de Início:",
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Step 1
          _buildStepItem(
            step: "1",
            icon: Icons.ios_share,
            title: "Toque em Compartilhar",
            description: "No Safari, selecione o ícone de compartilhamento na barra inferior do navegador.",
          ),
          const SizedBox(height: 14),

          // Step 2
          _buildStepItem(
            step: "2",
            icon: Icons.add_box_outlined,
            title: "Adicionar à Tela de Início",
            description: "Role a lista de ações e toque na opção 'Adicionar à Tela de Início'.",
          ),
          const SizedBox(height: 14),

          // Step 3
          _buildStepItem(
            step: "3",
            icon: Icons.notifications_none,
            title: "Abra pelo ícone criado",
            description: "Acesse o KinCare diretamente pela tela inicial e autorize o recebimento de notificações.",
          ),
          const SizedBox(height: 24),

          // Close button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: KinColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: KinColors.primary.withValues(alpha: 0.12),
          child: Text(
            step,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KinColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: KinColors.text),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KinColors.text)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}