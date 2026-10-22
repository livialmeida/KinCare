import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showAlertDialog('Atenção!', 'Preencha todos os campos!');
      return;
    }

    if (password != confirm) {
      _showAlertDialog('Erro', 'As senhas não conferem');
      return;
    }

    if (password.length < 6) {
      _showAlertDialog("Erro", "A senha deve ter no mínimo 6 caracteres");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Logic: Integration with your AuthProvider happen here
      await context.read<AuthProvider>().signUp(
          email,
          password,
          name,
      );

      if (mounted) {
        _showAlertDialog("Sucesso", "Conta criada com sucesso!", isSuccess: true);
      }
    } catch (error) {
      if (mounted) {
        _showAlertDialog('Erro no Cadastro', "Não foi possível realizar o cadastro.");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAlertDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (isSuccess) Navigator.pop(context);
                },
                child: const Text("OK"),
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Criar Conta 🌿",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: KinColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Cadastre-se para colaborar com a despensa e refeições familiares",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: KinColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildLabel("Nome"),
                      TextField(
                        controller: _nameController,
                        decoration: AppTheme.inputDecoration(
                            hint: "Como você quer ser chamado(a)?",
                            context: context,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel("E-mail"),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: AppTheme.inputDecoration(
                            hint: "exemplo@email.com",
                            context: context,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel("Senha"),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: AppTheme.inputDecoration(
                            hint: "Mínimo 6 caracteres",
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
                      const SizedBox(height: 16),

                      _buildLabel("Confirmar Senha"),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        decoration: AppTheme.inputDecoration(
                            hint: "Repita sua senha",
                            context: context,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                              size: 22,
                            ),
                            onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KinColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                "Criar Conta",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                ),
                            ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Já tem conta? Entrar",
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
      padding: const EdgeInsets.only(bottom: 6),
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