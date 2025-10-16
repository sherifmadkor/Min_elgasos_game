import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class AvatarPickerScreen extends StatelessWidget {
  const AvatarPickerScreen({super.key});

  // FREE avatars (emojis)
  static const List<String> freeAvatars = [
    '🕵️‍♂️','😎','🤖','👑','🧠','🔥','⚡','🎩',
    '🐱','🐺','🐼','🐸','🦊','🐯','🦁','🐵',
    '👻','💀','🎭','🦹','🧙‍♂️','🥷','👨‍🚀','🤠',
    '😈','👹','👺','🤡','👽','🛸','🚀','💎',
    '🦈','🦅','🦉','🐲','🦄','🐉','🦋','🐙',
    '⭐','🌟','💫','🌙','☄️','🎯','🎪','🎨',
  ];

  // PREMIUM avatars (locked placeholders as PNG assets)
  static const List<String> premiumAvatars = [
    'assets/avatars/premium_1.png',
    'assets/avatars/premium_2.png',
    'assets/avatars/premium_3.png',
    'assets/avatars/premium_4.png',
    'assets/avatars/premium_5.png',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final languageService = LanguageService.of(context);
    final isRtl = languageService.isRtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.chooseAvatarTitle),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.free, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              _AvatarGrid(
                items: freeAvatars,
                locked: false,
                isEmoji: true,
                onPick: (value) => Navigator.of(context).pop<String>(value),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 6),
                  Text(l10n.comingSoonPremium, style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 8),
              _AvatarGrid(
                items: premiumAvatars,
                locked: true,
                isEmoji: false,
                onPick: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.premiumAvatarsMessage)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({
    required this.items,
    required this.locked,
    required this.isEmoji,
    required this.onPick,
  });

  final List<String> items;
  final bool locked;
  final bool isEmoji;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final value = items[i];
        return InkWell(
          onTap: locked ? null : () => onPick(value),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 2,
              ),
              color: locked
                  ? Colors.black.withOpacity(0.35)
                  : colorScheme.primary.withOpacity(0.15),
            ),
            child: Stack(
              children: [
                Center(
                  child: isEmoji
                      ? Text(
                    value,
                    style: const TextStyle(fontSize: 36),
                  )
                      : Image.asset(value, fit: BoxFit.cover),
                ),
                if (locked)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Icon(Icons.lock, size: 26, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
