import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';
import 'package:kincare/features/family/presentation/widgets/modal_manage_family.dart';
import 'package:kincare/features/family/presentation/widgets/modal_user_guide.dart';
import 'package:kincare/features/account/presentation/pages/food_history_screen.dart';
import 'package:kincare/features/family/presentation/widgets/pantry_access_button.dart';
import 'package:kincare/core/utils/platform_helper.dart';
import 'package:kincare/features/account/presentation/widgets/modal_ios_install_guide.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isSavingName = false;
  bool _isSendingReset = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args?['openFamilyModal'] == true || args?['openPendingApprovals'] == true) {
        _openFamilyModal();
      }
    });
  }

  void _handleLogout(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Encerrar Sessão"),
        content: const Text("Deseja realmente sair da sua conta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
            },
            child: const Text("Sair", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openFamilyModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ModalManageFamily(),
    );
  }

  void _openEditNameDialog(AuthProvider auth, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Alterar Nome",
            style: TextStyle(fontWeight: FontWeight.bold, color: KinColors.text),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    "Nome de exibição",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KinColors.text),
                  ),
                ),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: AppTheme.inputDecoration(
                    hint: "Informe seu nome",
                    context: ctx,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Informe um nome válido.";
                    }
                    if (value.trim().length < 2) {
                      return "O nome deve conter ao menos 2 caracteres.";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);

                  navigator.pop();

                  setState(() => _isSavingName = true);
                  try {
                    await auth.updateProfileName(nameController.text.trim());
                  } catch (error) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
                    );
                  } finally {
                    if (mounted) setState(() => _isSavingName = false);
                  }
                }
              },
              child: const Text("Salvar", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handlePasswordReset(AuthProvider auth) {
    final email = auth.userProfile?['email'];
    if (email == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Redefinir Senha", style: TextStyle(fontWeight: FontWeight.bold, color: KinColors.text)),
          content: Text("Deseja enviar o link de redefinição de senha para o endereço $email?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);

                navigator.pop();

                setState(() => _isSendingReset = true);
                try {
                  await auth.resetPassword(email);

                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (spamCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(
                          children: [
                            Icon(Icons.mail_outline, color: KinColors.primary),
                            SizedBox(width: 8),
                            Text("E-mail Enviado", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("O link para redefinição foi encaminhado para o endereço cadastrado."),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Caso não localize a mensagem na Caixa de Entrada em instantes, verifique a pasta de Spam ou Lixo Eletrônico.",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KinColors.text, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(spamCtx),
                            child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(error.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isSendingReset = false);
                }
              },
              child: const Text("Enviar", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openIosInstallGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModalIosInstallGuide(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.userProfile;
    final theme = Theme.of(context);

    final bool canManageFamily = profile?['role'] == 'admin';
    final bool isSupport = profile?['role'] == 'support';
    final String currentName = profile?['name'] ?? "Usuário";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFFF0F0F0),
                        child: Icon(Icons.person, size: 40, color: KinColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      // Role Badge
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: KinColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile?['role'] == 'admin'
                              ? 'Administrador'
                              : 'Suporte & Cozinha',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: KinColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings Menu
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CONFIGURAÇÕES DA CONTA",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: "Nome de Exibição",
                        onTap: _isSavingName ? null : () => _openEditNameDialog(auth, currentName),
                      ),
                      if (canManageFamily)
                        _buildMenuItem(
                          icon: Icons.people_outline,
                          title: "Gerenciar Membros",
                          onTap: _openFamilyModal,
                        ),
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: "Segurança e Senha",
                        onTap: _isSendingReset ? null : () => _handlePasswordReset(auth),
                      ),
                      if (PlatformHelper.isIOS)
                        _buildMenuItem(
                          icon: Icons.apple,
                          title: "Configurar Notificações no iOS",
                          onTap: _openIosInstallGuide,
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        "CONTEÚDO E RECURSOS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isSupport) const PantryAccessButton(),
                      if (canManageFamily)
                        _buildMenuItem(
                          icon: Icons.history_edu_outlined,
                          title: "Histórico de Consumo",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FoodHistoryScreen()),
                            );
                          },
                        ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: "Guia de Utilização",
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (ctx) => const ModalUserGuide(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: () => _handleLogout(auth),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE5E5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Color(0xFFFF6B6B), size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Encerrar Sessão",
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Processing Overlay
          if (_isSavingName || _isSendingReset)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(color: KinColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: onTap == null ? Colors.grey : KinColors.text),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: onTap == null ? Colors.grey : KinColors.text,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}