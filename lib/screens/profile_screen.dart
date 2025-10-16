import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth_repository.dart';
import 'background_container.dart';
import 'avatar_picker_screen.dart';
import '../widgets/rank_emblem_png.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AuthRepository();
    final uid = repo.currentUid;
    final l10n = AppLocalizations.of(context)!;
    final languageService = LanguageService();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        centerTitle: true,
        actions: const [
        ],
      ),
      body: BackgroundContainer(
        child: uid == null
            ? Center(child: Text(l10n.noUserLoggedIn))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || !snap.data!.exists) {
              return Center(child: Text(l10n.noUserData));
            }
            final data = snap.data!.data()!;
            final displayName = (data['displayName'] ?? '') as String;
            final avatarEmoji = (data['avatarEmoji'] ?? '🕵️‍♂️') as String;
            final xp = (data['xp'] ?? 0) as int;
            final rankName = (data['rank'] ?? 'Iron') as String;

            final stats = (data['stats'] as Map?) ?? {};
            final games = (stats['gamesPlayed'] ?? 0) as int;
            final wins = (stats['wins'] ?? 0) as int;
            final spyWins = (stats['spyWins'] ?? 0) as int;
            final detectiveWins = (stats['detectiveWins'] ?? 0) as int;
            
            // Remove rank registry logic since we're using PNGs now

            return Directionality(
              textDirection: languageService.isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),

                  // Avatar + Name
                  Center(
                    child: Column(
                      children: [
                        // Row with Avatar and Rank Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Avatar with edit pencil
                            GestureDetector(
                              onTap: () async {
                                final picked = await Navigator.of(context).push<String>(
                                  MaterialPageRoute(
                                    builder: (_) => const AvatarPickerScreen(),
                                    fullscreenDialog: true,
                                  ),
                                );
                                if (picked != null) {
                                  await repo.updateUserDoc({'avatarEmoji': picked});
                                }
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(avatarEmoji, style: const TextStyle(fontSize: 44)),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Rank Emblem PNG
                            RankEmblemPNG(
                              rankName: rankName,
                              size: 150,  // Increased size
                              enableGlow: true,
                              enableAnimation: true,
                              showName: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name with edit pencil
                        GestureDetector(
                          onTap: () async {
                            final newName = await _askForName(context, displayName);
                            if (newName != null && newName.trim().isNotEmpty) {
                              await repo.updateProfile(displayName: newName.trim());
                              await repo.updateUserDoc({'displayName': newName.trim()});
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(displayName, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Rank Information
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getLocalizedRankName(context, rankName),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${l10n.xpPoints(xp)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.xpPoints(xp),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _StatTile(title: l10n.gamesPlayed, value: games.toString()),
                  _StatTile(title: l10n.wins, value: wins.toString()),
                  _StatTile(title: l10n.spyWins, value: spyWins.toString()),
                  _StatTile(title: l10n.detectiveWins, value: detectiveWins.toString()),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.back),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<String?> _askForName(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.changeName),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: l10n.enterNewName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(l10n.save)),
        ],
      ),
    );
  }

  String _getLocalizedRankName(BuildContext context, String rankName) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return rankName;
    
    switch (rankName.toLowerCase()) {
      case 'iron': return l10n.rankIron;
      case 'bronze': return l10n.rankBronze;
      case 'silver': return l10n.rankSilver;
      case 'gold': return l10n.rankGold;
      case 'platinum': return l10n.rankPlatinum;
      case 'emerald': return l10n.rankEmerald;
      case 'diamond': return l10n.rankDiamond;
      case 'master': return l10n.rankMaster;
      case 'grandmaster': return l10n.rankGrandmaster;
      case 'challenger': return l10n.rankChallenger;
      default: return rankName;
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
