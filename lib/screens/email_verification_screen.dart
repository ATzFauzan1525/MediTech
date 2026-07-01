import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app;
import '../theme/app_theme.dart';
import '../config/app_config.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _canResend = true;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _startEmailCheck();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _canResend = false;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startEmailCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            timer.cancel();
            if (mounted) {
              _showVerifiedDialog();
            }
          }
        }
      } catch (_) {}
    });
  }

  void _showVerifiedDialog() {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email Terverifikasi!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Email kamu berhasil diverifikasi. Silakan lanjutkan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                navigator.pop();
                navigator.pushNamedAndRemoveUntil(
                  AppRoutes.onboarding1,
                  (route) => false,
                );
              },
              child: const Text('Lanjutkan ke Onboarding'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resendEmail() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    final authProvider = context.read<app.AuthProvider>();
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await authProvider.resendEmailVerification();
      if (mounted) {
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Email verifikasi telah dikirim ulang.\nCek folder Spam/Junk jika tidak di inbox.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi email diperlukan untuk melanjutkan.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.darkBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 50,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Verifikasi Email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kami telah mengirim link verifikasi ke:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Buka email kamu dan klik link verifikasi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Setelah diverifikasi, kamu akan otomatis masuk',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: (_canResend && !_isResending) ? _resendEmail : null,
                      icon: _isResending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              color: _canResend
                                  ? AppColors.primaryBlue
                                  : AppColors.grey,
                            ),
                      label: Text(
                        _isResending
                            ? 'Mengirim...'
                            : _canResend
                                ? 'Kirim Ulang Email'
                                : 'Tunggu $_resendCooldown detik',
                        style: TextStyle(
                          color: _canResend
                              ? AppColors.primaryBlue
                              : AppColors.grey,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
