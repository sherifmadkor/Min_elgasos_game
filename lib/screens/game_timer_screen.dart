import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/screens/instructions_screen.dart';
import 'package:min_elgasos_game/screens/second_screen.dart';
import 'package:min_elgasos_game/slide_transition.dart';
import 'package:min_elgasos_game/screens/background_container.dart';
import '../l10n/app_localizations.dart';

class GameTimerScreen extends StatefulWidget {
  final int minutes;
  final List<bool> spyList;
  final String chosenItem;

  const GameTimerScreen({
    super.key,
    required this.minutes,
    required this.spyList,
    required this.chosenItem,
  });

  @override
  State<GameTimerScreen> createState() => _GameTimerScreenState();
}

class _GameTimerScreenState extends State<GameTimerScreen> {
  late int totalSeconds;
  late int remainingSeconds;
  Timer? _timer;
  bool isRunning = false;
  bool isPaused = false;
  bool _manuallyStopped = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final String _adUnitId = 'ca-app-pub-3611835750308121/1315161028';

  @override
  void initState() {
    super.initState();
    totalSeconds = widget.minutes * 60;
    remainingSeconds = totalSeconds;
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

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
        if (remainingSeconds <= 10 && remainingSeconds > 0) {
          await _audioPlayer.play(AssetSource('sounds/countdown.mp3'));
        }
      } else {
        timer.cancel();
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
        setState(() => isRunning = false);
      }
    });
  }

  void _pauseOrResumeTimer() {
    if (isRunning) {
      _timer?.cancel();
      setState(() {
        isRunning = false;
        isPaused = true;
      });
    } else if (isPaused) {
      setState(() {
        isRunning = true;
        isPaused = false;
      });
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
  }

  void _confirmExit() {
    final l10n = AppLocalizations.of(context)!;
    _showConfirmationDialog(
      title: l10n.exitGame,
      onConfirm: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }

  void _startNewGame() {
    Navigator.pushReplacement(context, createSlideRoute(const SecondScreen()));
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
  

  Future<bool> _onWillPop() async {
    _confirmExit();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool finished = remainingSeconds == 0;
    final bool showEndGameButtons = !isRunning && (finished || _manuallyStopped);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: BackgroundContainer(
        child: Scaffold(
          appBar: AppBar(
            // Force the AppBar to be Left-to-Right to fix button placement
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
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/vector.png', height: 120),
                        const SizedBox(height: 30),
                        _buildTimerWidget(),
                        const SizedBox(height: 40),
                        if (!isRunning && !isPaused && !finished && !_manuallyStopped)
                          CoolButton(
                            onPressed: _startTimer,
                            icon: Icons.play_arrow_rounded,
                            text: AppLocalizations.of(context)!.startTimer,
                          ),
                        if (isRunning || isPaused) _buildPauseAndVoteButtons(),
                        if (showEndGameButtons) ...[
                          const SizedBox(height: 20),
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
                if (_isBannerLoaded && _bannerAd != null)
                  Container(
                    color: Colors.black,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerWidget() {
    double progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 12,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
          Center(
            child: Text(
              _formatTime(remainingSeconds),
              style: AppTheme.textTheme.displayLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseAndVoteButtons() {
    return Column(
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
        CoolButton(
          onPressed: _stopTimerCompletely,
          text: AppLocalizations.of(context)!.startVoting,
          icon: Icons.how_to_vote_rounded,
        ),
      ],
    );
  }
}
