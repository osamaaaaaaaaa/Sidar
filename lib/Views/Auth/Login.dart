import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:skincare/Services/auth_service.dart';
import 'package:skincare/Services/auth_profile_ui.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Services/supabase_config.dart';
import 'package:skincare/Views/Home/Home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Onboarding/onboarding_questionnaire_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();

  final _supabase = Supabase.instance.client;
  Future<void>? _googleInitialization;

  bool _isLoading = false;
  bool _isPasswordHidden = true;
  bool _isGoogleLoading = false;
  bool _navigating = false;
  // Temporary flag to hide Google Sign-In/Sign-Up UI while preserving implementation
  final bool _showGoogleSignIn = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    AuthFlow.instance;
    _authSubscription = _supabase.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn && state.session != null) {
        Future<void>(() async {
          // The password/native flows finish their own request. This handles
          // OAuth callbacks arriving after splash; never route over signup.
          if (!mounted ||
              _isLoading ||
              _navigating ||
              ModalRoute.of(context)?.isCurrent != true)
            return;
          await _completeLogin();
        });
      }
    }, onError: (Object _) {});
  }

  Future<void> _completeLogin() async {
    if (!mounted || _navigating || AuthFlow.instance.recoveryPending) return;
    _navigating = true;
    await AuthService().prepareSession();
    if (!mounted || AuthFlow.instance.recoveryPending) return;
    if (!AuthService().isLoggedIn) {
      _navigating = false;
      return;
    }
    Get.offAll(() => const HomeView());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email'.tr;
    }

    final emailRegex = RegExp(
      r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$",
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address'.tr;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter your password'.tr;
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters'.tr;
    }

    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_isLoading || _isGoogleLoading || _navigating) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = await AuthService().signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;
      if (response.session != null) {
        await _completeLogin();
        return;
      }

      _showError('Unable to sign in right now. Please try again.'.tr);
    } on AuthException catch (e) {
      log(e.toString(), name: 'LoginError');

      _showError(_mapAuthError(e.message));
    } catch (e) {
      log(e.toString(), name: 'LoginError');
      _showError('Something went wrong while signing in. Please try again.'.tr);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading || _isLoading || _navigating) return;

    setState(() => _isGoogleLoading = true);

    try {
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.replace(query: '', fragment: '').toString(),
        );
        return;
      }
      if (SupabaseConfig.googleWebClientId.isEmpty) {
        throw const AuthException('Missing GOOGLE_WEB_CLIENT_ID.');
      }
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      if (isIOS && SupabaseConfig.googleIosClientId.isEmpty) {
        throw const AuthException('Missing GOOGLE_IOS_CLIENT_ID.');
      }

      try {
        _googleInitialization ??= GoogleSignIn.instance.initialize(
          clientId: isIOS ? SupabaseConfig.googleIosClientId : null,
          serverClientId: SupabaseConfig.googleWebClientId,
        );
        await _googleInitialization;

        const scopes = <String>['email', 'profile'];
        final googleAccount = await GoogleSignIn.instance.authenticate(
          scopeHint: scopes,
        );
        final idToken = googleAccount.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw const AuthException('Google did not return an ID token.');
        }

        final authorization =
            await googleAccount.authorizationClient.authorizationForScopes(
              scopes,
            ) ??
            await googleAccount.authorizationClient.authorizeScopes(scopes);

        final response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: authorization.accessToken,
        );
        final user = response.user;
        if (user == null) {
          throw const AuthException('Supabase did not return a user.');
        }

        if (!mounted) return;
        await _completeLogin();
        return;
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return;
        }
        log(
          'Native Google sign in failed, trying OAuth fallback: $e',
          name: 'GoogleLogin',
        );
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.sidarai.app://login-callback',
        );
      } catch (nativeError) {
        log(
          'Native Google sign in error, trying OAuth fallback: $nativeError',
          name: 'GoogleLogin',
        );
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.sidarai.app://login-callback',
        );
      }
    } on AuthException catch (e) {
      log(e.toString(), name: 'GoogleLoginError');
      _showError(_mapAuthError(e.message));
    } catch (e) {
      log(e.toString(), name: 'GoogleLoginError');
      _showError('google_sign_in_failed'.tr);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _showForgotPasswordSheet() async {
    _resetEmailController.text = _emailController.text.trim();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final localFormKey = GlobalKey<FormState>();
        bool sending = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> sendResetEmail() async {
              if (sending) return;

              final isValid = localFormKey.currentState?.validate() ?? false;
              if (!isValid) return;

              setModalState(() => sending = true);

              try {
                await _supabase.auth.resetPasswordForEmail(
                  _resetEmailController.text.trim(),
                  redirectTo: kIsWeb
                      ? Uri.base
                            .replace(
                              queryParameters: {'auth_action': 'recovery'},
                              fragment: '',
                            )
                            .toString()
                      : null,
                );

                if (!context.mounted) return;
                Navigator.of(context).pop();

                AppFeedback.success(
                  'We sent password reset instructions to your email address.'
                      .tr,
                  title: 'Check your email'.tr,
                );
              } on AuthException catch (e) {
                _showError(_mapAuthError(e.message));
              } catch (_) {
                _showError(
                  'Unable to send reset email right now. Please try again.'.tr,
                );
              } finally {
                if (context.mounted) {
                  setModalState(() => sending = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: AppTheme.glassPanel(
                borderRadius: 24,
                child: Form(
                  key: localFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset password'.tr,
                        style: AppTheme.headingStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your email and we will send you reset instructions.'
                            .tr,
                        style: AppTheme.bodyStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        controller: _resetEmailController,
                        hint: 'email'.tr,
                        icon: Icons.email_outlined,
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 18),
                      AppTheme.goldButton(
                        text: 'Send reset link'.tr,
                        onPressed: sendResetEmail,
                        isLoading: sending,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password.'.tr;
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email before signing in.'.tr;
    }
    if (lower.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.'.tr;
    }
    if (lower.contains('network')) {
      return 'Please check your internet connection and try again.'.tr;
    }
    if (lower.contains('user not found')) {
      return 'No account was found with this email.'.tr;
    }

    return message;
  }

  void _showError(String message) {
    if (!mounted) return;
    AppFeedback.error(message, title: 'Sign in failed'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppTheme.backgroundGradient(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildLogoSection(),
                    const SizedBox(height: 42),

                    _buildTextField(
                      controller: _emailController,
                      hint: 'email'.tr,
                      icon: Icons.email_outlined,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 18),

                    _buildTextField(
                      controller: _passwordController,
                      hint: 'password'.tr,
                      icon: Icons.lock_outline_rounded,
                      validator: _validatePassword,
                      obscureText: _isPasswordHidden,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      suffixIcon: IconButton(
                        splashRadius: 20,
                        onPressed: () {
                          setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          });
                        },
                        icon: Icon(
                          _isPasswordHidden
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    _buildForgotPassword(),
                    const SizedBox(height: 30),
                    _buildLoginButton(),
                    if (_showGoogleSignIn) ...[
                      const SizedBox(height: 30),
                      _buildDivider(),
                      const SizedBox(height: 26),
                      _buildSocialLogin(),
                    ],
                    const SizedBox(height: 32),
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppTheme.goldGlowShadow,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.primary.withOpacity(.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                'assets/images/sidar-emblem-clean.png',
                width: 145,
                height: 145,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'SIDAR AI',
          style: AppTheme.headingStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'login_subtitle'.tr,
          textAlign: TextAlign.center,
          style: AppTheme.bodyStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: AppTheme.bodyStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      cursorColor: AppColors.primary,
      decoration: AppTheme.inputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildLoginButton() {
    return AppTheme.goldButton(
      text: 'login_btn'.tr,
      onPressed: _handleLogin,
      isLoading: _isLoading,
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showForgotPasswordSheet,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
        child: Text(
          'forgot_password'.tr,
          style: AppTheme.bodyStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.primary.withOpacity(.15),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or_continue_with'.tr,
            style: AppTheme.bodyStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.primary.withOpacity(.15),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            (defaultTargetPlatform == TargetPlatform.iOS &&
                SupabaseConfig.googleIosClientId.isNotEmpty))
          _socialIconCard(
            'assets/images/google-color-icon.png',
            _signInWithGoogle,
            isLoading: _isGoogleLoading,
          ),
      ],
    );
  }

  Widget _socialIconCard(
    String asset,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AppTheme.glassPanel(
        width: 62,
        height: 62,
        padding: EdgeInsets.zero,
        borderRadius: 18,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                )
              : Image.asset(asset, width: 25, height: 25),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'no_account'.tr,
          style: AppTheme.bodyStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.to(() => const OnboardingQuestionnaireView());
          },
          child: Text(
            'sign_up_now'.tr,
            style: AppTheme.bodyStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
