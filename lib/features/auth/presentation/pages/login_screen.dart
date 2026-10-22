import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showAlertDialog('Atenção', 'Por favor, preencha e-mail e senha.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.signIn(email, password);
    } catch (error) {
      _showAlertDialog("Erro no Login...", "E-mail ou senha incorretos.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logic: Triggers a password recovery pop-up with immediate spam awareness warnings
  void _handleForgotPassword() {
    final recoveryEmailController = TextEditingController(text: _emailController.text.trim());
    final formKey = GlobalKey<FormState>();

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              "Recuperar Senha",
              style: TextStyle(fontWeight: FontWeight.bold, color: KinColors.text),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Digite seu e-mail cadastrado para receber as instruções de redefinição de senha.",
                    style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "E-mail",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KinColors.text),
                    ),
                  ),
                  TextFormField(
                    controller: recoveryEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: AppTheme.inputDecoration(
                        hint: "exemplo@email.com",
                        context: ctx,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Por favor, preencha o e-mail!";
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
                      final navigator = Navigator.of(context);
                      final email = recoveryEmailController.text.trim();

                      navigator.pop();

                      setState(() => _isLoading = true);
                      try {
                        final auth = context.read<AuthProvider>();
                        await auth.resetPassword(email);

                        if (mounted) {
                          showDialog(
                              context: context,
                              builder: (spamCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.mail_outline, color: KinColors.primary),
                                    SizedBox(width: 8),
                                    Text("Verifique seu E-mail", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("O link de redefinição foi enviado para:\n$email"),
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
                                          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                "Importante: Verifique sua caixa de Spam ou Lixo Eletrônico, pois o e-mail costuma ser direcionado para lá!",
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
                        if (mounted) setState(() => _isLoading = false);
                      }
                    }
                  },
                  child: const Text("Enviar", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
    );
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinColors.background,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top,
            color: KinColors.primary,
          ),
          Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      const Text(
                        "KinCare 🌿",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: KinColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Gestão colaborativa de despensa e refeições familiares",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: KinColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // E-mail input group
                      _buildLabel("E-mail"),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: AppTheme.inputDecoration(
                            hint: "exemplo@email.com",
                            context: context,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Password input group
                      _buildLabel("Senha"),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: AppTheme.inputDecoration(
                            hint: "******",
                            context: context,
                        ).copyWith(
                          suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                                size: 22,
                              ),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _isLoading ? null : _handleForgotPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Esqueceu sua senha?",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KinColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Entrar",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Register link
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        "Ainda não tem uma conta? Cadastre-se",
                        style: TextStyle(color: KinColors.primary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: KinColors.text,
        ),
      ),
    );
  }
}