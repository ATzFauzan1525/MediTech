import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String? oobCode;
  final bool isAuthenticatedMode;

  const ChangePasswordScreen({
    super.key,
    this.oobCode,
    this.isAuthenticatedMode = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isValidating = true;
  bool _isValidCode = false;
  String? _currentOobCode;

  @override
  void initState() {
    super.initState();
    if (widget.isAuthenticatedMode) {
      _isValidating = false;
      _isValidCode = true;
      return;
    }

    _currentOobCode = widget.oobCode;
    if (_currentOobCode != null && _currentOobCode!.isNotEmpty) {
      _validateCode(_currentOobCode!);
    } else {
      _checkClipboard();
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';

      // Extract oobCode from Firebase URL
      final oobCode = _extractOobCode(text);
      if (oobCode != null && mounted) {
        setState(() {
          _currentOobCode = oobCode;
        });
        _showClipboardDialog(oobCode);
      } else if (mounted) {
        setState(() {
          _isValidating = false;
        });
        _showManualInputDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
        _showManualInputDialog();
      }
    }
  }

  String? _extractOobCode(String text) {
    // Try to extract from URL
    final uri = Uri.tryParse(text);
    if (uri != null && uri.queryParameters.containsKey('oobCode')) {
      return uri.queryParameters['oobCode'];
    }

    // Try to extract raw oobCode (if user copied just the code)
    if (text.isNotEmpty && text.length > 20 && !text.contains(' ')) {
      return text;
    }

    return null;
  }

  void _showClipboardDialog(String oobCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.content_paste_go,
                size: 30,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kode Ditemukan!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tautan reset password terdeteksi di clipboard. Gunakan kode ini untuk mengubah password?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isValidating = false;
              });
              _showManualInputDialog();
            },
            child: const Text('Batal'),
          ),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _validateCode(oobCode);
              },
              child: const Text('Gunakan'),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off,
                size: 30,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kode Tidak Ditemukan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Copy URL dari email reset password, lalu tempel di bawah:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tempel URL di sini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text('Batal'),
          ),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                final oobCode = _extractOobCode(text);
                if (oobCode != null) {
                  Navigator.pop(context);
                  _validateCode(oobCode);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('URL tidak valid. Pastikan kamu copy yang benar.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              child: const Text('Gunakan'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateCode(String oobCode) async {
    if (mounted) setState(() => _isValidating = true);

    try {
      await FirebaseAuth.instance.verifyPasswordResetCode(oobCode);
      if (mounted) {
        setState(() {
          _currentOobCode = oobCode;
          _isValidating = false;
          _isValidCode = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _isValidCode = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isAuthenticatedMode) {
      await _changePasswordAuthenticated();
      return;
    }

    if (_currentOobCode == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: _currentOobCode!,
        newPassword: _passwordController.text,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Gagal mengubah password.';
        if (e.code == 'expired-action-code') {
          msg = 'Tautan sudah kedaluwarsa. Silakan minta tautan baru.';
        } else if (e.code == 'invalid-action-code') {
          msg = 'Tautan tidak valid. Silakan minta tautan baru.';
        } else if (e.code == 'weak-password') {
          msg = 'Password terlalu lemah.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePasswordAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login tidak valid. Silakan login ulang.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_passwordController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Gagal mengubah password.';
        if (e.code == 'wrong-password') {
          msg = 'Password lama salah.';
        } else if (e.code == 'requires-recent-login') {
          msg = 'Sesi sudah kadaluwarsa. Silakan login ulang.';
        } else if (e.code == 'weak-password') {
          msg = 'Password terlalu lemah.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah password. Coba lagi.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleBackNavigation() {
    if (!mounted) return;

    if (widget.isAuthenticatedMode) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Password Berhasil Diubah!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login dengan password baru kamu.',
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: const Text('Kembali ke Login'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 16),
              Text(
                _currentOobCode != null
                    ? 'Memverifikasi tautan...'
                    : 'Mengecek clipboard...',
                style: TextStyle(fontSize: 14, color: AppColors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isValidCode) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tautan Tidak Valid',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tautan reset password sudah kedaluwarsa atau tidak valid. Silakan minta tautan baru.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isValidating = true;
                        _isValidCode = false;
                      });
                      _checkClipboard();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    child: const Text('Kembali ke Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 20,
                    left: 24,
                    right: 24,
                    bottom: 40,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.darkBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: _handleBackNavigation,
                        icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ubah Password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan password baru kamu',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.softBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 60,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Password Baru',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isAuthenticatedMode
                                ? 'Masukkan password lama dan password baru untuk memperbarui akun kamu.'
                                : 'Pastikan password baru kamu kuat dan mudah diingat.',
                            style: const TextStyle(fontSize: 14, color: AppColors.grey),
                          ),
                          const SizedBox(height: 24),
                          if (widget.isAuthenticatedMode)
                            CustomTextField(
                              label: 'Password Lama',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              controller: _currentPasswordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password lama wajib diisi';
                                }
                                return null;
                              },
                            ),
                          if (widget.isAuthenticatedMode) const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Password Baru',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Konfirmasi Password',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }
                              if (value != _passwordController.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Text('Ubah Password'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Kembali ke ',
                                style: const TextStyle(color: AppColors.grey),
                              ),
                              GestureDetector(
                                onTap: _handleBackNavigation,
                                child: Text(
                                  widget.isAuthenticatedMode ? 'Profil' : 'Login',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
