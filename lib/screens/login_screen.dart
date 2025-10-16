import 'package:flutter/material.dart';
import 'auth_repository.dart';
import 'background_container.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.nextRoute});

  /// Where to go after successful login. If null, defaults to '/mainMenu'.
  final String? nextRoute;

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  /// Helper to build from onGenerateRoute with arguments
  static Widget fromRouteSettings(RouteSettings settings) {
    final arg = settings.arguments;
    final next = (arg is String && arg.isNotEmpty) ? arg : null;
    return LoginScreen(nextRoute: next);
  }
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthRepository().signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;

      final next = widget.nextRoute ?? '/mainMenu';
      Navigator.pushNamedAndRemoveUntil(context, next, (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final languageService = LanguageService.of(context);
    final isRtl = languageService.isRtl;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
        centerTitle: true,
      ),
      body: BackgroundContainer(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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

                        // Email (LTR typing)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              hintText: l10n.emailHint,
                              border: inputBorder,
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide: BorderSide(color: scheme.primary, width: 2),
                              ),
                            ),
                            validator: (v) {
                              final val = (v ?? '').trim();
                              if (val.isEmpty) return l10n.pleaseEnterEmail;
                              if (!val.contains('@') || !val.contains('.')) {
                                return l10n.invalidEmail;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password (LTR typing)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _loading ? null : _login(),
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              hintText: l10n.passwordHint,
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
                              if (val.isEmpty) return l10n.pleaseEnterPassword;
                              if (val.length < 6) {
                                return l10n.passwordTooShort;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text(l10n.login),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Go to Create Account (use pop result to continue to /online)
                        TextButton(
                          onPressed: _loading ? null : () async {
                            final result = await Navigator.pushNamed(context, '/create_account');
                            if (mounted && result == true) {
                              final next = widget.nextRoute ?? '/mainMenu';
                              Navigator.pushNamedAndRemoveUntil(context, next, (_) => false);
                            }
                          },
                          child: Text(l10n.createNewAccount),
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
