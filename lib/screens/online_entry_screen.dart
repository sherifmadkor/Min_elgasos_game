import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'background_container.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class OnlineEntryScreen extends StatefulWidget {
  const OnlineEntryScreen({super.key});

  @override
  State<OnlineEntryScreen> createState() => _OnlineEntryScreenState();
}

class _OnlineEntryScreenState extends State<OnlineEntryScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // If user already logged in, skip straight to online screen
    final user = FirebaseAuth.instance.currentUser;
    if (mounted && user != null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/online');
      });
      return;
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _goLogin() async {
    // Tell login where to go AFTER success
    await Navigator.pushNamed(context, '/login', arguments: '/online');
    // When we come back, check again (user might have logged in)
    _checkAuth();
  }

  Future<void> _goCreateAccount() async {
    // Your CreateAccountScreen should pop(true) on success (as we coded earlier).
    final result = await Navigator.pushNamed(context, '/create_account');
    if (mounted && result == true) {
      Navigator.pushReplacementNamed(context, '/online');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = LanguageService.of(context);
    final isRtl = languageService.isRtl;
    
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playOnlineTitle),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.onlineIntroMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _goLogin,
                          child: Text(l10n.login),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _goCreateAccount,
                          child: Text(l10n.createNewAccount),
                        ),
                      ),
                    ],
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
