import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _firebaseUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  StreamSubscription? _profileSubscription;

  // Getters
  User? get user => _firebaseUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  String _getUiErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este e-mail já está sendo usado por outra conta.';
      case 'invalid-email':
        return 'O endereço de e-mail não é válido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'too-many-requests':
        return 'Muitas tentativas consecutivas. Por segurança, aguarde alguns instantes e tente novamente.';
      default:
        return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  Future<void> _onAuthStateChanged(User? currentUser) async {
    _profileSubscription?.cancel();

    if (currentUser != null) {
      _firebaseUser = currentUser;

      // Technical: Real-time sync with user document
      _profileSubscription = _db
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((docSnap) async {
        if (docSnap.exists) {
          final profileData = docSnap.data() as Map<String, dynamic>;

          _userProfile = {
            ...profileData,
            'name': profileData['name'] ?? currentUser.displayName ?? 'Membro da Família',
          };

          // 1. Technical: Sync platform without race conditions (only if document exists)
          final String detectedOS = _resolveCurrentPlatform();
          final String? storedOS = profileData['deviceOS'] as String?;

          if (storedOS != detectedOS) {
            _db.collection('users').doc(currentUser.uid).set({
              'deviceOS': detectedOS,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true)).catchError((e) {
              if (kDebugMode) {
                debugPrint('Failed to update deviceOS: $e');
              }
            });
          }
        } else {
          // Document has not yet been populated by signUp
          _userProfile = null;
        }
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) {
          debugPrint('Profile stream error: $e');
        }
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _firebaseUser = null;
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Technical: Login / SignIn
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getUiErrorMessage(e.code));
    }
  }

  // Logic: Register a new account with 'pending' role and safe platform fallback
  Future<void> signUp(
      String email,
      String password,
      String name,
      ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final detectedOS = _resolveCurrentPlatform();

      // Technical: Atomic storage in 'users' collection strictly satisfying Firestore security rules
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': 'pending',
        'deviceOS': detectedOS,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(_getUiErrorMessage(e.code));
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Firestore registration error: ${e.code} - ${e.message}');
      }
      throw Exception('Erro ao salvar os dados do perfil: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected registration crash: $e');
      }
      throw Exception('Ocorreu um erro inesperado durante o cadastro.');
    }
  }

  // Update profile name
  Future<void> updateProfileName(String newName) async {
    if (_firebaseUser == null) {
      throw Exception('Nenhum usuário autenticado encontrado.');
    }

    try {
      await _db.collection('users').doc(_firebaseUser!.uid).update({
        'name': newName,
      });

      await _auth.currentUser?.updateDisplayName(newName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update name error: $e');
      }
      throw Exception('Ocorreu um erro ao atualizar o nome. Tente novamente.');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getUiErrorMessage(e.code));
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Logout error: $error');
      }
    }
  }

  // Technical: Resolve client platform safely across Web, iOS and Android
  String _resolveCurrentPlatform() {
    if (kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios_web';
      if (defaultTargetPlatform == TargetPlatform.android) return 'android_web';
      return 'desktop_web';
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  // Checks OS consistency upon loading user profile and triggers guidance dialog if OS changed
  Future<void> syncDeviceOSAndCheckChange({
    required BuildContext context,
  }) async {
    if (_firebaseUser == null || _userProfile == null) return;

    final String currentOS = _resolveCurrentPlatform();
    final String? previousOS = _userProfile!['deviceOS'] as String?;

    if (previousOS == null) {
      try {
        await _db.collection('users').doc(_firebaseUser!.uid).set({
          'deviceOS': currentOS,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Device OS initial registration error: $e');
        }
      }
    } else if (previousOS != currentOS) {
      try {
        await _db.collection('users').doc(_firebaseUser!.uid).set({
          'deviceOS': currentOS,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (context.mounted) {
          _showOsChangeDialog(context, platform: currentOS);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Device OS migration error: $e');
        }
      }
    }
  }

  // UI dialog informing the user about the notification channel change
  void _showOsChangeDialog(BuildContext context, {required String platform}) {
    final bool isIOS = platform == 'ios_web' || platform == 'ios';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: const [
              Icon(Icons.install_mobile, color: Colors.teal),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Instalar KinCare',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          ),
          content: Text(
            isIOS
                ? 'Para usar como app e receber notificações no iPhone, toque no botão "Compartilhar" do Safari e selecione "Adicionar à Tela de Início".'
                : 'Para facilitar seu acesso diário, toque no menu do Chrome (três pontinhos) e escolha "Adicionar à tela inicial" ou "Instalar aplicativo".',
            style: const TextStyle(fontSize: 14.0),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  bool canModifyUser(String targetUserUid) {
    if (_firebaseUser == null || _userProfile == null) return false;

    final role = _userProfile!['role'];
    return role == 'admin';
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}