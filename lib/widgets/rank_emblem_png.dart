import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';

class RankEmblemPNG extends StatefulWidget {
  final String rankName;
  final double size;
  final bool enableAnimation;
  final bool enableGlow;
  final bool showName;

  const RankEmblemPNG({
    super.key,
    required this.rankName,
    this.size = 150,  // Increased default size
    this.enableAnimation = true,
    this.enableGlow = true,
    this.showName = false,
  });

  @override
  State<RankEmblemPNG> createState() => _RankEmblemPNGState();
}

class _RankEmblemPNGState extends State<RankEmblemPNG>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Breathing animation (gentle scale effect)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // Wing glow pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Overall glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    if (widget.enableAnimation) {
      _rotationController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _getRankImagePath(String rankName) {
    switch (rankName.toLowerCase()) {
      case 'iron':
        return 'assets/images/ranks/Season_2023_-_Iron.png';
      case 'bronze':
        return 'assets/images/ranks/Season_2023_-_Bronze.png';
      case 'silver':
        return 'assets/images/ranks/Season_2023_-_Silver.png';
      case 'gold':
        return 'assets/images/ranks/Season_2023_-_Gold.png';
      case 'platinum':
        return 'assets/images/ranks/Season_2023_-_Platinum.png';
      case 'emerald':
        return 'assets/images/ranks/Season_2023_-_Emerald.png';
      case 'diamond':
        return 'assets/images/ranks/Season_2023_-_Diamond.png';
      case 'master':
        return 'assets/images/ranks/Season_2023_-_Master.png';
      case 'grandmaster':
        return 'assets/images/ranks/Season_2023_-_Grandmaster.png';
      case 'challenger':
        return 'assets/images/ranks/Season_2023_-_Challenger (1).png';
      default:
        return 'assets/images/ranks/Season_2023_-_Iron.png';
    }
  }

  Color _getRankGlowColor(String rankName) {
    switch (rankName.toLowerCase()) {
      case 'iron':
        return const Color(0xFF9E9EA3);  // Brighter iron metallic
      case 'bronze':
        return const Color(0xFFCD7F32);  // Brighter bronze copper
      case 'silver':
        return const Color(0xFFE8E8E8);  // Brighter silver
      case 'gold':
        return const Color(0xFFFFD700);  // Pure bright gold
      case 'platinum':
        return const Color(0xFF5BE8FF);  // Brighter cyan
      case 'emerald':
        return const Color(0xFF66FF88);  // Brighter emerald green
      case 'diamond':
        return const Color(0xFF5C9EFF);  // Brighter diamond blue
      case 'master':
        return const Color(0xFFB555FF);  // Brighter purple
      case 'grandmaster':
        return const Color(0xFFFF5577);  // Brighter red
      case 'challenger':
        return const Color(0xFF00EEFF);  // Bright cyan/aqua
      default:
        return const Color(0xFF9E9EA3);
    }
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

  @override
  Widget build(BuildContext context) {
    final glowColor = _getRankGlowColor(widget.rankName);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Enhanced glow effect behind the image
              if (widget.enableGlow && widget.enableAnimation)
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: widget.size * 1.25,
                      height: widget.size * 1.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Inner bright glow
                          BoxShadow(
                            color: glowColor.withOpacity(_glowAnimation.value * 0.9),
                            blurRadius: 25,
                            spreadRadius: 8,
                          ),
                          // Outer softer glow
                          BoxShadow(
                            color: glowColor.withOpacity(_glowAnimation.value * 0.6),
                            blurRadius: 40,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              
              // Main rank image with breathing and wing glow effects
              AnimatedBuilder(
                animation: widget.enableAnimation 
                    ? Listenable.merge([_rotationAnimation, _glowAnimation])
                    : _glowAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.enableAnimation ? _rotationAnimation.value : 1.0,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(_getRankImagePath(widget.rankName)),
                          fit: BoxFit.contain,
                        ),
                        // Enhanced brighter glow effects
                        boxShadow: widget.enableGlow ? [
                          // Inner bright glow
                          BoxShadow(
                            color: glowColor.withOpacity(widget.enableAnimation ? _glowAnimation.value * 0.95 : 0.8),
                            blurRadius: widget.enableAnimation ? 30 + (_glowAnimation.value * 15) : 20,
                            spreadRadius: widget.enableAnimation ? 8 + (_glowAnimation.value * 4) : 6,
                          ),
                          // Middle glow layer
                          BoxShadow(
                            color: glowColor.withOpacity(widget.enableAnimation ? _pulseAnimation.value * 0.7 : 0.5),
                            blurRadius: widget.enableAnimation ? 45 + (_pulseAnimation.value * 20) : 30,
                            spreadRadius: widget.enableAnimation ? 12 + (_pulseAnimation.value * 6) : 8,
                          ),
                          // Outer atmospheric glow
                          BoxShadow(
                            color: glowColor.withOpacity(widget.enableAnimation ? _glowAnimation.value * 0.3 : 0.25),
                            blurRadius: widget.enableAnimation ? 50 + (_glowAnimation.value * 15) : 35,
                            spreadRadius: widget.enableAnimation ? 12 + (_glowAnimation.value * 6) : 10,
                          ),
                        ] : null,
                      ),
                    ),
                  );
                },
              ),
              
              // Particle effects for higher ranks
              if (widget.enableAnimation && _isHigherRank(widget.rankName))
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(widget.size * 1.5, widget.size * 1.5),
                      painter: ParticleEffectPainter(
                        animationValue: _pulseController.value,
                        glowColor: glowColor,
                        rankName: widget.rankName,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        
        // Rank name
        if (widget.showName) ...[
          const SizedBox(height: 8),
          Text(
            _getLocalizedRankName(context, widget.rankName),
            style: TextStyle(
              fontSize: widget.size * 0.12,
              fontWeight: FontWeight.bold,
              color: glowColor,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 3,
                ),
                if (widget.enableGlow)
                  Shadow(
                    color: glowColor.withOpacity(0.5),
                    blurRadius: 5,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool _isHigherRank(String rankName) {
    return ['master', 'grandmaster', 'challenger'].contains(rankName.toLowerCase());
  }
}

class ParticleEffectPainter extends CustomPainter {
  final double animationValue;
  final Color glowColor;
  final String rankName;

  ParticleEffectPainter({
    required this.animationValue,
    required this.glowColor,
    required this.rankName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final particlePaint = Paint()
      ..color = glowColor.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Different particle patterns for different ranks
    switch (rankName.toLowerCase()) {
      case 'master':
        _drawMasterParticles(canvas, center, size, particlePaint);
        break;
      case 'grandmaster':
        _drawGrandmasterParticles(canvas, center, size, particlePaint);
        break;
      case 'challenger':
        _drawChallengerParticles(canvas, center, size, particlePaint);
        break;
    }
  }

  void _drawMasterParticles(Canvas canvas, Offset center, Size size, Paint paint) {
    // Wing area glow particles (left and right sides)
    for (int i = 0; i < 6; i++) {
      // Left wing particles
      double leftX = center.dx - size.width * (0.15 + i * 0.02);
      double leftY = center.dy + math.sin(animationValue * 2 + i) * 5;
      double leftSize = 1.5 + math.sin(animationValue * 3 + i) * 0.5;
      canvas.drawCircle(Offset(leftX, leftY), leftSize, paint);
      
      // Right wing particles
      double rightX = center.dx + size.width * (0.15 + i * 0.02);
      double rightY = center.dy + math.sin(animationValue * 2 + i + math.pi) * 5;
      double rightSize = 1.5 + math.sin(animationValue * 3 + i + math.pi) * 0.5;
      canvas.drawCircle(Offset(rightX, rightY), rightSize, paint);
    }
  }

  void _drawGrandmasterParticles(Canvas canvas, Offset center, Size size, Paint paint) {
    // Pulsing wing edge particles
    for (int i = 0; i < 8; i++) {
      double wingOffset = size.width * 0.18;
      
      // Left wing edge
      double leftX = center.dx - wingOffset;
      double leftY = center.dy - size.height * 0.1 + (i * size.height * 0.025);
      double leftOpacity = 0.5 + math.sin(animationValue * 4 + i) * 0.3;
      
      Paint leftPaint = Paint()
        ..color = glowColor.withOpacity(leftOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(Offset(leftX, leftY), 2, leftPaint);
      
      // Right wing edge
      double rightX = center.dx + wingOffset;
      double rightY = center.dy - size.height * 0.1 + (i * size.height * 0.025);
      double rightOpacity = 0.5 + math.sin(animationValue * 4 + i + math.pi) * 0.3;
      
      Paint rightPaint = Paint()
        ..color = glowColor.withOpacity(rightOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(Offset(rightX, rightY), 2, rightPaint);
    }
  }

  void _drawChallengerParticles(Canvas canvas, Offset center, Size size, Paint paint) {
    // Energy flowing along wing outlines
    for (int i = 0; i < 10; i++) {
      double progress = (animationValue + i * 0.1) % 1.0;
      
      // Left wing flow
      double leftX = center.dx - size.width * (0.1 + progress * 0.15);
      double leftY = center.dy - size.height * 0.05 + math.sin(progress * math.pi) * size.height * 0.08;
      
      paint.color = HSVColor.fromAHSV(
        0.8 - progress * 0.3,
        (240 + progress * 120) % 360, // Blue to cyan flow
        1.0,
        1.0,
      ).toColor();
      
      double leftSize = 2.0 - progress * 1.5;
      canvas.drawCircle(Offset(leftX, leftY), leftSize, paint);
      
      // Right wing flow
      double rightX = center.dx + size.width * (0.1 + progress * 0.15);
      double rightY = center.dy - size.height * 0.05 + math.sin(progress * math.pi) * size.height * 0.08;
      
      double rightSize = 2.0 - progress * 1.5;
      canvas.drawCircle(Offset(rightX, rightY), rightSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ParticleEffectPainter ||
        oldDelegate.animationValue != animationValue;
  }
}

// Mini version for compact displays
class MiniRankEmblemPNG extends StatelessWidget {
  final String rankName;
  final double size;

  const MiniRankEmblemPNG({
    super.key,
    required this.rankName,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return RankEmblemPNG(
      rankName: rankName,
      size: size,
      enableAnimation: false,
      enableGlow: false,
      showName: false,
    );
  }
}