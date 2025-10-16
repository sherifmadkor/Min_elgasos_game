import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_repository.dart';
import 'background_container.dart';
import 'avatar_picker_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  // Default emoji avatar
  String _selectedEmoji = '🕵️‍♂️';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_loading) return;
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const AvatarPickerScreen(),
        fullscreenDialog: true,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedEmoji = picked);
    }
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = AuthRepository();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final displayName = _nameCtrl.text.trim();

    try {
      // 1) Create auth user + ensure Firestore users/{uid}
      await repo.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      // 2) Save avatar (emoji) in Firestore (avoid setting FirebaseAuth.photoURL with non-URL)
      await repo.updateUserDoc({
        'avatarKind': 'emoji',
        'avatarEmoji': _selectedEmoji,
      });

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountCreatedSuccess)),
      );
      Navigator.of(context).pop(true);
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
        title: Text(l10n.createAccountTitle),
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
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const SizedBox(height: 8),

                        // Error banner (shows real message)
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
                                Expanded(
                                  child: SelectableText(
                                    _error!,
                                    style: TextStyle(color: scheme.onErrorContainer),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Emoji avatar + picker
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickAvatar,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 92,
                                      height: 92,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            scheme.primary.withOpacity(0.25),
                                            scheme.secondary.withOpacity(0.25),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: scheme.primary.withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _selectedEmoji,
                                          style: const TextStyle(fontSize: 44),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: scheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: _pickAvatar,
                                icon: const Icon(Icons.emoji_emotions_outlined),
                                label: Text(l10n.chooseAvatar),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Name
                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.name,
                            hintText: l10n.nameHint,
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: BorderSide(color: scheme.primary, width: 2),
                            ),
                          ),
                          validator: (v) {
                            final val = (v ?? '').trim();
                            if (val.isEmpty) return l10n.pleaseEnterName;
                            if (val.length < 2) return l10n.nameTooShort;
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Email (LTR & left-aligned so English looks natural)
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

                        // Password (LTR for dots & any English)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _loading ? null : _onSubmit(),
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
                                tooltip: _obscure ? l10n.show : l10n.hide,
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
                        const SizedBox(height: 22),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(scheme.primary),
                              overlayColor: WidgetStatePropertyAll(
                                scheme.primaryContainer.withOpacity(0.15),
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            onPressed: _loading ? null : _onSubmit,
                            child: _loading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text(l10n.createAccount),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
                          child: Text(l10n.alreadyHaveAccountLogin),
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
