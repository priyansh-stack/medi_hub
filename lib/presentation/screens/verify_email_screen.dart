import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_model.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../widgets/custom_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  final UserModel user;

  const VerifyEmailScreen({
    super.key,
    required this.user,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    setState(() {
      _secondsRemaining = seconds;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _secondsRemaining = 0;
        });
        timer.cancel();
      }
    });
  }

  void _resendVerification() {
    if (_secondsRemaining > 0) return;
    context.read<AuthBloc>().add(AuthResendVerificationRequested());
    _startCooldown(60);
  }

  void _checkVerificationStatus() {
    context.read<AuthBloc>().add(AuthVerifyEmailCheckRequested());
  }

  void _showEmailCorrectionDialog() {
    final correctionController = TextEditingController(text: widget.user.email);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Correct Email Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If you made a typo during registration, enter your corrected email below. We will resend the verification link.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: correctionController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'New Email Address',
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
              final newEmail = correctionController.text.trim();
              final error = Validators.validateEmail(newEmail);
              if (error == null) {
                context.read<AuthBloc>().add(AuthCorrectEmailRequested(newEmail));
                Navigator.pop(ctx);
                _startCooldown(60);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Update & Resend'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight > 40 ? constraints.maxHeight - 40 : 0,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primaryLight, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_unread_outlined,
                                      size: 40,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Check Your Inbox',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'We sent a verification link to:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      widget.user.email,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Instruction card
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Click the verification link in the email to activate your account. If you do not see it in your inbox, please check your Spam or Junk folder.',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  height: 1.4,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Divider(color: AppColors.border, height: 1),
                                        SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.timer_outlined, size: 20, color: AppColors.warning),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Links expire after 24 hours. You can request a fresh link at any time below.',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  height: 1.4,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Actions Section
                              Column(
                                children: [
                                  CustomButton(
                                    text: 'I Have Verified My Email',
                                    icon: Icons.refresh_rounded,
                                    isLoading: isLoading,
                                    onPressed: _checkVerificationStatus,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomButton(
                                    text: _secondsRemaining > 0
                                        ? 'Resend Email in ${_secondsRemaining}s'
                                        : 'Resend Verification Email',
                                    variant: ButtonVariant.outline,
                                    icon: Icons.forward_to_inbox_rounded,
                                    onPressed: _secondsRemaining > 0 ? null : _resendVerification,
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Wrong email address? Change it here'),
                                    onPressed: _showEmailCorrectionDialog,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
