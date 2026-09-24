import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/pressable_scale.dart';
import 'sign_up_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loadingEmail = false;
  bool _loadingGoogle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loadingEmail = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      _closeAuthFlow();
    } on AuthException catch (e) {
      if (mounted) _showError(AppStrings.of(context).authErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _loadingGoogle = true);
    try {
      // isNewUser is irrelevant here: signing in never onboards regardless
      // (a brand-new account just lands on Home's empty-babies state,
      // which already offers "create a baby profile" itself).
      await ref.read(authRepositoryProvider).signInWithGoogle();
      _closeAuthFlow();
    } on AuthException catch (e) {
      if (mounted) _showError(AppStrings.of(context).authErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  // This screen was pushed on top of the root route (which renders
  // WelcomeScreen or RootShell depending on auth state). Once sign-in
  // succeeds, _AuthGate swaps what that root route shows to RootShell, but
  // that alone doesn't pop *this* pushed route — without this, the user
  // stays stuck looking at the sign-in form until they manually go back.
  void _closeAuthFlow() {
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _resetPassword() async {
    final s = AppStrings.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError(s.enterEmailForReset);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        AppSnackBar.showSuccess(context, s.resetEmailSent(email));
      }
    } catch (_) {
      if (mounted) _showError(s.resetEmailFailed);
    }
  }

  void _showError(String message) => AppSnackBar.showError(context, message);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.signIn)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: s.email),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? s.invalidEmail
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: s.password),
                        obscureText: true,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? s.required : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PressableScale(
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text(s.forgotPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PressableScale(
                        child: ElevatedButton(
                          onPressed: _loadingEmail ? null : _submitEmail,
                          child: _loadingEmail
                              ? AppLoadingIndicator(size: 18, color: AppColors.of(context).onPrimary)
                              : Text(s.signInButton),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(s.or),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GoogleSignInButton(
                        onPressed: _submitGoogle,
                        loading: _loadingGoogle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Center(
                child: PressableScale(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: s.noAccountYet,
                            style: TextStyle(
                              color: AppColors.of(context).inkSoft,
                            ),
                          ),
                          TextSpan(
                            text: s.createAccountLink,
                            style: TextStyle(
                              color: AppColors.of(context).primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
