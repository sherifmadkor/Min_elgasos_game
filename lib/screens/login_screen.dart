import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_repository.dart';
import 'background_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = AuthRepository();
    try {
      await repo.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح ✅')),
      );

      // Go to your main menu / online lobby list
      Navigator.of(context).pushReplacementNamed('/mainMenu');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onForgot() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل بريدًا إلكترونيًا صالحًا أولاً')),
      );
      return;
    }
    try {
      await AuthRepository().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: BackgroundContainer(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const SizedBox(height: 8),
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scheme.error.withOpacity(0.5)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline, color: scheme.error),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!)),
                              ],
                            ),
                          ),

                        // Email (force LTR)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'example@mail.com',
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide: BorderSide(color: scheme.primary, width: 2),
                              ),
                            ),
                            validator: (v) {
                              final val = (v ?? '').trim();
                              if (val.isEmpty) return 'من فضلك أدخل البريد الإلكتروني';
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'بريد إلكتروني غير صالح';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password (force LTR)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _loading ? null : _onLogin(),
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: '•••••••',
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide: BorderSide(color: scheme.primary, width: 2),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              ),
                            ),
                            validator: (v) {
                              final val = v ?? '';
                              if (val.isEmpty) return 'من فضلك أدخل كلمة المرور';
                              if (val.length < 6) {
                                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _loading ? null : _onForgot,
                            child: const Text('نسيت كلمة المرور؟'),
                          ),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _loading ? null : _onLogin,
                            child: _loading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Text('تسجيل الدخول'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context).pushNamed('/createAccount'),
                          child: const Text('لا تملك حساباً؟ إنشاء حساب'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
