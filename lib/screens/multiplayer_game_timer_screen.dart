import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/instructions_screen.dart';
import 'package:min_elgasos_game/slide_transition.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import 'package:min_elgasos_game/models/room_models.dart';
import 'package:min_elgasos_game/services/game_stats_service.dart';
import 'package:min_elgasos_game/services/realtime_room_service.dart';
import 'package:min_elgasos_game/widgets/rank_emblem_png.dart';
import 'package:min_elgasos_game/services/app_lifecycle_service.dart';
import '../l10n/app_localizations.dart';

class MultiplayerGameTimerScreen extends StatefulWidget {
  final int minutes;
  final List<bool> spyList;
  final String chosenItem;
  final GameRoom gameRoom;

  const MultiplayerGameTimerScreen({
    super.key,
    required this.minutes,
    required this.spyList,
    required this.chosenItem,
    required this.gameRoom,
  });

  @override
  State<MultiplayerGameTimerScreen> createState() => _MultiplayerGameTimerScreenState();
}

class _MultiplayerGameTimerScreenState extends State<MultiplayerGameTimerScreen> {
  late int totalSeconds;
  late int remainingSeconds;
  Timer? _timer;
  bool isRunning = false;
  bool isPaused = false;
  bool _manuallyStopped = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GameStatsService _gameStatsService = GameStatsService();
  final RealtimeRoomService _roomService = RealtimeRoomService();
  bool _gameResultRecorded = false;
  bool _hasNavigatedToVoting = false; // Navigation guard to prevent double transitions
  
  // Check if current user is host
  bool get _isHost {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId != null && currentUserId == widget.gameRoom.hostId;
  }

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final String _adUnitId = 'ca-app-pub-3611835750308121/1315161028';

  @override
  void initState() {
    super.initState();
    totalSeconds = widget.minutes * 60;
    remainingSeconds = totalSeconds;
    AppLifecycleService().setCurrentRoom(widget.gameRoom.id);
    // Auto-start timer when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _bannerAd?.dispose();
    AppLifecycleService().setCurrentRoom(null);
    super.dispose();
  }

  Future<void> _loadAd() async {
    final AnchoredAdaptiveBannerAdSize? size =
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.of(context).size.width.truncate());

    if (size == null) {
      debugPrint('Unable to get ad size.');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    )..load();
  }

  String _formatTime(int secs) {
    final minutes = (secs ~/ 60).toString().padLeft(2, '0');
    final seconds = (secs % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startTimer() {
    if (isRunning || isPaused) return;
    setState(() {
      isRunning = true;
      _manuallyStopped = false;
    });
    _tick();
  }
  
  void _startNextRound() {
    // Reset timer for next round without leaving the room
    _timer?.cancel();
    setState(() {
      remainingSeconds = totalSeconds;
      isRunning = false;
      isPaused = false;
      _manuallyStopped = false;
      _gameResultRecorded = false;
    });
  }

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds > 0) {
        if (mounted) {
          setState(() => remainingSeconds--);
        }
        if (remainingSeconds <= 10 && remainingSeconds > 0) {
          await _audioPlayer.play(AssetSource('sounds/countdown.mp3'));
        }
      } else {
        timer.cancel();
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
        if (mounted) {
          setState(() => isRunning = false);
        }
        if (!_gameResultRecorded && _isHost) {
          // Only host starts the voting phase
          _startVotingPhase();
        }
      }
    });
  }

  Future<void> _pauseOrResumeTimer() async {
    // Only host can control timer
    if (!_isHost) return;
    
    if (isRunning) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          isRunning = false;
          isPaused = true;
        });
      }
      // Update room state to pause timer for all players
      await _roomService.updateRoom(widget.gameRoom.id, {
        'timerPaused': true,
      });
    } else if (isPaused) {
      if (mounted) {
        setState(() {
          isRunning = true;
          isPaused = false;
        });
      }
      _tick();
      // Update room state to resume timer for all players
      await _roomService.updateRoom(widget.gameRoom.id, {
        'timerPaused': false,
      });
    }
  }

  void _syncTimerWithRoom(GameRoom room) {
    // Only sync if there's actually a state change to prevent unnecessary rebuilds
    if (room.timerPaused == true && (isRunning || !isPaused)) {
      // Host paused, pause local timer
      _timer?.cancel();
      if (mounted) {
        setState(() {
          isRunning = false;
          isPaused = true;
        });
      }
    } else if (room.timerPaused == false && isPaused && !isRunning) {
      // Host resumed from paused state, resume local timer
      // Only resume if we were previously paused, don't auto-start from initial state
      if (mounted) {
        setState(() {
          isRunning = true;
          isPaused = false;
        });
      }
      _tick();
    }
  }

  void _stopTimerCompletely() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
      isPaused = false;
      _manuallyStopped = true;
    });
    
    // Only host can start voting phase
    if (_isHost) {
      _startVotingPhase();
    }
  }

  Future<void> _startVotingPhase() async {
    try {
      // Clear votes and update phase to voting
      await _roomService.resetVotes(widget.gameRoom.id);
      await _roomService.setGamePhase(widget.gameRoom.id, 'voting');
      
      print('Timer: Started voting phase with Realtime Database');
      
      // Navigation will be handled by StreamBuilder when status changes
      // Removed duplicate navigation to prevent double transition
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting voting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmExit() {
    final l10n = AppLocalizations.of(context)!;
    _showConfirmationDialog(
      title: l10n.exitGame,
      onConfirm: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }

  void _startNewGame() {
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  void _showConfirmationDialog({required String title, required VoidCallback onConfirm}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(title, style: AppTheme.textTheme.headlineMedium?.copyWith(fontSize: 22)),
        content: Text(l10n.areYouSure, style: AppTheme.textTheme.bodyLarge),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.no, style: TextStyle(color: AppTheme.textSecondaryColor))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text(l10n.yes, style: TextStyle(color: AppTheme.accentColor))),
        ],
      ),
    );
  }

  void _showResultsDialog() {
    final timeSpent = totalSeconds - remainingSeconds;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(child: Text(AppLocalizations.of(context)!.gameResult, style: AppTheme.textTheme.headlineMedium)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.theWordWas,
                style: AppTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondaryColor),
              ),
              Text(
                widget.chosenItem,
                style: AppTheme.textTheme.headlineMedium?.copyWith(color: AppTheme.accentColor, fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 25, color: AppTheme.textSecondaryColor),
              Text("${AppLocalizations.of(context)!.timeSpent}: ${_formatTime(timeSpent)}", style: AppTheme.textTheme.bodyLarge),
              const SizedBox(height: 15),
              SizedBox(
                height: 150,
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.spyList.length,
                  itemBuilder: (context, index) {
                    final isSpy = widget.spyList[index];
                    return ListTile(
                      leading: Text(isSpy ? '🥷' : '🕵️', style: const TextStyle(fontSize: 24)),
                      title: Text("${AppLocalizations.of(context)!.playerNumber} ${index + 1}", style: AppTheme.textTheme.bodyLarge),
                      trailing: Text(isSpy ? AppLocalizations.of(context)!.spy : AppLocalizations.of(context)!.detective, style: AppTheme.textTheme.bodyMedium?.copyWith(color: isSpy ? Colors.redAccent : Colors.greenAccent)),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: CoolButton(
                text: AppLocalizations.of(context)!.newGame,
                icon: Icons.replay_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  _startNewGame();
                },
              ),
            )
          ],
        ));
  }
  
  void _showWhoWonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'Who Won? 🏆',
            style: AppTheme.textTheme.headlineMedium,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select the winning team:',
              style: AppTheme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWinnerButton(
                  emoji: '🥷',
                  label: 'Spies Won',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _recordGameResult(spiesWon: true);
                  },
                ),
                _buildWinnerButton(
                  emoji: '🕵️',
                  label: 'Detectives Won',
                  color: Colors.greenAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _recordGameResult(spiesWon: false);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWinnerButton({
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _recordGameResult({required bool spiesWon}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _gameResultRecorded = true;
      _showResultsDialog();
      return;
    }
    
    if (!mounted) return;
    final ctx = context;
    
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accentColor,
        ),
      ),
    );
    
    try {
      final playerIndex = await _showPlayerSelectionDialog();
      if (playerIndex == null) {
        if (mounted) Navigator.pop(ctx);
        _showResultsDialog();
        return;
      }
      
      final isSpy = widget.spyList[playerIndex];
      final playerWon = (isSpy && spiesWon) || (!isSpy && !spiesWon);
      
      final result = await _gameStatsService.recordGameResult(
        userId: currentUser.uid,
        result: playerWon ? GameResult.win : GameResult.loss,
        role: isSpy ? PlayerRole.spy : PlayerRole.detective,
        allPlayerIds: widget.gameRoom.players.map((p) => p.id).toList(),
        isOnlineGame: true,
      );
      
      if (mounted) Navigator.pop(ctx);
      
      if (result != null) {
        _showXPGainedDialog(result);
      } else {
        _gameResultRecorded = true;
        _showResultsDialog();
      }
    } catch (e) {
      if (mounted) Navigator.pop(ctx);
      _gameResultRecorded = true;
      _showResultsDialog();
    }
  }
  
  Future<int?> _showPlayerSelectionDialog() async {
    return await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'Which Player Are You? 🎮',
            style: AppTheme.textTheme.headlineMedium,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.spyList.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => Navigator.pop(context, index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentColor),
                  ),
                  child: Center(
                    child: Text(
                      'P${index + 1}',
                      style: AppTheme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  void _showXPGainedDialog(Map<String, dynamic> result) {
    final xpGained = result['xpGained'] as int;
    final newTotalXP = result['newTotalXP'] as int;
    final oldRank = result['oldRank'] as String;
    final newRank = result['newRank'] as String;
    final rankChanged = result['rankChanged'] as bool;
    final winStreak = result['winStreak'] as int;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Column(
            children: [
              Text(
                rankChanged ? '🎉 Rank Up!' : '✨ XP Gained!',
                style: AppTheme.textTheme.headlineMedium,
              ),
              if (rankChanged) ...[  
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RankEmblemPNG(rankName: oldRank, size: 50),
                    const Icon(Icons.arrow_forward, color: AppTheme.accentColor),
                    RankEmblemPNG(rankName: newRank, size: 50),
                  ],
                ),
              ],
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: AppTheme.accentColor, size: 20),
                  Text(
                    '$xpGained XP',
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Total XP: $newTotalXP',
              style: AppTheme.textTheme.bodyLarge,
            ),
            if (winStreak > 1) ...[  
              const SizedBox(height: 8),
              Text(
                '🔥 Win Streak: $winStreak',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (rankChanged) ...[  
              const SizedBox(height: 16),
              Text(
                'Congratulations on reaching $newRank!',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: CoolButton(
              text: 'Continue',
              icon: Icons.check,
              onPressed: () {
                Navigator.pop(context);
                _gameResultRecorded = true;
                _showResultsDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    _confirmExit();
    return false;
  }

  GameRoom? _lastRoomState;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameRoom?>(
      stream: _roomService.getRoomById(widget.gameRoom.id),
      builder: (context, snapshot) {
        final room = snapshot.data ?? widget.gameRoom;

        // Check for voting status FIRST, before any other processing
        // This prevents the screen from building the timer UI before navigating
        if (room.status == RoomStatus.voting) {
          if (!_hasNavigatedToVoting) {
            _hasNavigatedToVoting = true; // Set guard to prevent duplicate navigation
            print('MultiplayerTimer: Detected voting status, navigating...');

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/voting',
                  arguments: {
                    'gameRoom': room,
                    'currentUserId': _roomService.auth.currentUser!.uid,
                  },
                );
              }
            });
          }
          // Always return loading screen when in voting status to prevent any UI flash
          return BackgroundContainer(
            child: const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentColor,
                ),
              ),
            ),
          );
        }

        // Only process other state changes if room state actually changed
        if (_lastRoomState == null || _hasRoomStateChanged(_lastRoomState!, room)) {
          _lastRoomState = room;

          // Handle room state changes for non-host players
          if (!_isHost && room.timerPaused != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _syncTimerWithRoom(room);
            });
          }
        }

        return _buildTimerScreen(context, room);
      },
    );
  }

  bool _hasRoomStateChanged(GameRoom oldRoom, GameRoom newRoom) {
    return oldRoom.status != newRoom.status || 
           oldRoom.timerPaused != newRoom.timerPaused;
  }

  Widget _buildTimerScreen(BuildContext context, GameRoom room) {
    final bool finished = remainingSeconds == 0;
    final bool showEndGameButtons = !isRunning && (finished || _manuallyStopped);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: BackgroundContainer(
        child: Scaffold(
          appBar: AppBar(
            leading: Directionality(
              textDirection: TextDirection.ltr,
              child: IconButton(
                icon: const Icon(Icons.home_rounded),
                onPressed: _confirmExit,
                tooltip: AppLocalizations.of(context)!.exitToHome,
              ),
            ),
            actions: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded),
                      onPressed: () => Navigator.push(context, createSlideRoute(const InstructionsScreen())),
                      tooltip: AppLocalizations.of(context)!.gameRules,
                    ),
                    IconButton(
                      icon: const Icon(Icons.assessment_outlined),
                      onPressed: _showResultsDialog,
                      tooltip: AppLocalizations.of(context)!.result,
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Image.asset('assets/images/vector.png', height: 80),
                        const SizedBox(height: 15),
                        _buildTimerWidget(),
                        const SizedBox(height: 20),
                        _buildPlayersList(room),
                        const SizedBox(height: 20),
                        // Timer auto-starts, no need for start button
                        if ((isRunning || isPaused) && _isHost) _buildPauseAndVoteButtons(),
                        if ((isRunning || isPaused) && !_isHost) _buildPlayerWaitingIndicator(),
                        if (showEndGameButtons && !_gameResultRecorded && _isHost) ...[
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CoolButton(
                                onPressed: _startNextRound,
                                icon: Icons.skip_next_rounded,
                                text: 'Next Round',
                              ),
                              const SizedBox(width: 20),
                              CoolButton(
                                onPressed: _showWhoWonDialog,
                                icon: Icons.assignment_turned_in_rounded,
                                text: AppLocalizations.of(context)!.result,
                              ),
                            ],
                          )
                        ],
                        if (showEndGameButtons && !_gameResultRecorded && !_isHost) ...[
                          const SizedBox(height: 15),
                          Text(
                            'Waiting for host to start next round...',
                            style: AppTheme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (showEndGameButtons && _gameResultRecorded) ...[
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CoolButton(
                                onPressed: _startNewGame,
                                icon: Icons.replay_rounded,
                                text: AppLocalizations.of(context)!.newGame,
                              ),
                              const SizedBox(width: 20),
                              CoolButton(
                                onPressed: _showResultsDialog,
                                icon: Icons.assignment_turned_in_rounded,
                                text: AppLocalizations.of(context)!.result,
                              ),
                            ],
                          )
                        ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isBannerLoaded && _bannerAd != null)
                SafeArea(
                  top: false,
                  child: Container(
                    color: Colors.black,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerWidget() {
    double progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    return RepaintBoundary(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Reduce animation duration for smoother experience, especially for non-hosts
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: _isHost ? 100 : 200),
              tween: Tween(begin: progress, end: progress),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 12,
                backgroundColor: AppTheme.surfaceColor.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ),
            Center(
              child: DefaultTextStyle(
                style: AppTheme.textTheme.displayLarge!,
                child: Text(_formatTime(remainingSeconds)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseAndVoteButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _pauseOrResumeTimer,
          icon: Icon(
            isPaused ? Icons.play_circle_fill_rounded : Icons.pause_circle_filled_rounded,
            size: 70,
            color: Colors.white,
          ),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 20),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: CoolButton(
                onPressed: _stopTimerCompletely,
                text: AppLocalizations.of(context)!.startVoting,
                icon: Icons.how_to_vote_rounded,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlayerWaitingIndicator() {
    return Column(
      children: [
        Icon(
          isPaused ? Icons.pause_circle_filled_rounded : Icons.timer_rounded,
          size: 50,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(height: 15),
        Text(
          isPaused 
            ? 'Timer Paused by Host' 
            : 'Game in Progress...',
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Wait for the host to control the timer',
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildPlayersList(GameRoom room) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.playersInGame,
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.textSecondaryColor),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: room.players.length,
              itemBuilder: (context, index) {
                final player = room.players[index];
                final wins = room.sessionWins?[player.id] ?? 0;
                final losses = room.sessionLosses?[player.id] ?? 0;
                final isCurrentUser = player.id == FirebaseAuth.instance.currentUser?.uid;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentUser 
                        ? AppTheme.accentColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Text(
                        player.avatar,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  player.name,
                                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isCurrentUser ? FontWeight.bold : null,
                                    color: isCurrentUser ? AppTheme.accentColor : null,
                                  ),
                                ),
                                if (player.isHost) ...[  
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                ],
                                if (isCurrentUser) ...[  
                                  const SizedBox(width: 4),
                                  Text(
                                    '(You)',
                                    style: AppTheme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.accentColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              player.rank,
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'W:$wins',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'L:$losses',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}