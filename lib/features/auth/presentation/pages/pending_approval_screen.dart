import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(),

              // Visual Indicator: Clean waiting state
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: KinColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: KinColors.primary,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                "Aguardando Aprovação",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: KinColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              const Text(
                "Seu cadastro foi realizado com sucesso. Por motivos de segurança, o acesso precisa ser autorizado por um administrador da casa.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                "Você receberá uma notificação assim que o seu cadastro for liberado.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // UI Hint: Reassures user that the screen automatically updates if kept open
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KinColors.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Atualização em tempo real ativa",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Secondary Action: Escape hatch to switch accounts
              TextButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: const Text(
                  "Sair desta conta",
                  style: TextStyle(
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}