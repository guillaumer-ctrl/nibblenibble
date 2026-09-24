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
import 'account_created_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loadingEmail = false;
  bool _loadingGoogle = false;

  @override
  void dispose() {
    _nameController.dispose();
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
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
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
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      _closeAuthFlow(onboard: result.isNewUser);
    } on AuthException catch (e) {
      if (mounted) _showError(AppStrings.of(context).authErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  // This screen was pushed on top of the root route (which renders
  // WelcomeScreen or RootShell depending on auth state). Once sign-up
  // succeeds, _AuthGate swaps what that root route shows to RootShell, but
  // that alone doesn't pop *this* pushed route — without this, the user
  // stays stuck looking at the sign-up form until they manually go back.
  //
  // From here the onboarding continues — a new account might be starting
  // its own baby's profile, or might exist only because someone invited
  // them to an existing one, so OnboardingChoiceScreen branches between the
  // two rather than forcing "Ajouter un bébé" on everyone. Pushed on top of
  // the now-first RootShell route rather than popping to it, so "back"
  // lands on Home, not on this form.
  //
  // [onboard] is always true for the email/password path (createUser fails
  // outright if the account already exists, so it's always a genuinely new
  // account) but not for Google: that same "Continuer avec Google" button
  // also transparently signs a *returning* user into their existing
  // account if they land here by mistake (e.g. tapped "Commencer" instead
  // of "J'ai déjà un compte") — onboarding them again risked nudging them
  // into creating a duplicate baby profile on top of their real one.
  void _closeAuthFlow({bool onboard = true}) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (onboard) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AccountCreatedScreen()));
    }
  }

  void _showError(String message) => AppSnackBar.showError(context, message);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(s.createAccount)),
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
                        controller: _nameController,
                        decoration: InputDecoration(labelText: s.firstName),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? s.required : null,
                      ),
                      const SizedBox(height: 14),
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
                            (v == null || v.length < 6) ? s.minSixChars : null,
                      ),
                      const SizedBox(height: 24),
                      PressableScale(
                        child: ElevatedButton(
                          onPressed: _loadingEmail ? null : _submitEmail,
                          child: _loadingEmail
                              ? AppLoadingIndicator(size: 18, color: AppColors.of(context).onPrimary)
                              : Text(s.createMyAccount),
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
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: s.alreadyHaveAccountLink,
                            style: TextStyle(
                              color: AppColors.of(context).inkSoft,
                            ),
                          ),
                          TextSpan(
                            text: s.signInLink,
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
