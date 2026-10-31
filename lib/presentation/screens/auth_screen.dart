import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

enum AuthTab { login, register }

class AuthScreen extends StatefulWidget {
  final AuthTab initialTab;
  final VoidCallback? onBackToHome;

  const AuthScreen({
    super.key,
    this.initialTab = AuthTab.login,
    this.onBackToHome,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthTab _currentTab;

  // Login Form Controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;

  // Register Form Controllers
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _registerObscurePassword = true;
  bool _registerObscureConfirm = true;
  bool _termsAccepted = true;
  String? _termsError;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant AuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() {
        _currentTab = widget.initialTab;
      });
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_loginFormKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthLoginSubmitted(
            email: _loginEmailController.text.trim(),
            password: _loginPasswordController.text,
          ),
        );
  }

  void _submitRegister() {
    setState(() {
      _termsError = _termsAccepted ? null : 'You must accept the terms to continue.';
    });

    if (!_registerFormKey.currentState!.validate() || !_termsAccepted) {
      return;
    }

    context.read<AuthBloc>().add(
          AuthRegisterSubmitted(
            fullName: _registerNameController.text.trim(),
            email: _registerEmailController.text.trim(),
            password: _registerPasswordController.text,
            termsAccepted: _termsAccepted,
          ),
        );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _loginEmailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address to receive password reset instructions.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                context.read<AuthBloc>().add(AuthPasswordResetRequested(email));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: widget.onBackToHome,
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'MediHub',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is AuthActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      // Segmented Tab Controller (Log In vs Register)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                label: 'Log In',
                                isSelected: _currentTab == AuthTab.login,
                                onTap: () {
                                  setState(() => _currentTab = AuthTab.login);
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildTabButton(
                                label: 'Register',
                                isSelected: _currentTab == AuthTab.register,
                                onTap: () {
                                  setState(() => _currentTab = AuthTab.register);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card containing the active view
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: _currentTab == AuthTab.login
                            ? _buildLoginView(isLoading)
                            : _buildRegisterView(isLoading),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView(bool isLoading) {
    return Container(
      key: const ValueKey('login_view'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log in to access your family health hub and records.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Email Address
            CustomTextField(
              controller: _loginEmailController,
              label: 'Email Address',
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 18),

            // Password
            CustomTextField(
              controller: _loginPasswordController,
              label: 'Password',
              hint: 'Enter your account password',
              prefixIcon: Icons.lock_outline,
              obscureText: _loginObscurePassword,
              validator: (val) => val == null || val.isEmpty ? 'Please enter your password' : null,
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _loginObscurePassword = !_loginObscurePassword;
                  });
                },
              ),
            ),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                ),
                child: const Text('Forgot Password?'),
              ),
            ),

            const SizedBox(height: 16),

            // Submit Button
            CustomButton(
              text: 'Log In',
              icon: Icons.login_rounded,
              isLoading: isLoading,
              onPressed: _submitLogin,
            ),

            const SizedBox(height: 22),

            // Not registered yet? Switch to Register
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "Not registered yet? ",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTab = AuthTab.register;
                    });
                  },
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterView(bool isLoading) {
    return Container(
      key: const ValueKey('register_view'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create MediHub Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Join MediHub to connect and manage your family health hub.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Full Name
            CustomTextField(
              controller: _registerNameController,
              label: 'Full Name',
              hint: 'e.g. Priyanshu Kumar',
              prefixIcon: Icons.person_outline,
              validator: Validators.validateFullName,
            ),
            const SizedBox(height: 16),

            // Email Address
            CustomTextField(
              controller: _registerEmailController,
              label: 'Email Address',
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),

            // Password
            CustomTextField(
              controller: _registerPasswordController,
              label: 'Password',
              hint: 'Min 8 chars with letters & numbers',
              prefixIcon: Icons.lock_outline,
              obscureText: _registerObscurePassword,
              validator: Validators.validatePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _registerObscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _registerObscurePassword = !_registerObscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            CustomTextField(
              controller: _registerConfirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: _registerObscureConfirm,
              validator: (val) => Validators.validateConfirmPassword(
                val,
                _registerPasswordController.text,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _registerObscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _registerObscureConfirm = !_registerObscureConfirm;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Terms & Conditions Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _termsAccepted,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _termsAccepted = val ?? false;
                        if (_termsAccepted) _termsError = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'I accept MediHub Terms of Service & Privacy Policy.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (_termsError != null) ...[
              const SizedBox(height: 6),
              Text(
                _termsError!,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            CustomButton(
              text: 'Register & Continue',
              icon: Icons.arrow_forward_rounded,
              isLoading: isLoading,
              onPressed: _submitRegister,
            ),

            const SizedBox(height: 22),

            // Already have an account? Switch to Login
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTab = AuthTab.login;
                    });
                  },
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

