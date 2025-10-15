import 'package:flutter/material.dart';
import 'dart:math';

class LoLRankInfo {
  final String name;
  final String arabicName;
  final int minXP;
  final int maxXP;
  final List<Color> colors;
  final List<Color> gemColors;
  final Color borderColor;
  final Color accentColor;
  final int wings; // Number of wings/gems

  const LoLRankInfo({
    required this.name,
    required this.arabicName,
    required this.minXP,
    required this.maxXP,
    required this.colors,
    required this.gemColors,
    required this.borderColor,
    required this.accentColor,
    required this.wings,
  });
}

class LoLRankSystem {
  static const List<LoLRankInfo> ranks = [
    // Iron
    LoLRankInfo(
      name: 'Iron',
      arabicName: 'حديدي',
      minXP: 0,
      maxXP: 99,
      colors: [Color(0xFF4A4A4A), Color(0xFF2C2C2C)],
      gemColors: [Color(0xFF666666), Color(0xFF444444)],
      borderColor: Color(0xFF2C2C2C),
      accentColor: Color(0xFF666666),
      wings: 0,
    ),
    // Bronze
    LoLRankInfo(
      name: 'Bronze',
      arabicName: 'برونزي',
      minXP: 100,
      maxXP: 299,
      colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
      gemColors: [Color(0xFFDEB887), Color(0xFFCD853F)],
      borderColor: Color(0xFF8B4513),
      accentColor: Color(0xFFD2691E),
      wings: 2,
    ),
    // Silver
    LoLRankInfo(
      name: 'Silver',
      arabicName: 'فضي',
      minXP: 300,
      maxXP: 599,
      colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
      gemColors: [Color(0xFFE6E6FA), Color(0xFFD3D3D3)],
      borderColor: Color(0xFF696969),
      accentColor: Color(0xFFDCDCDC),
      wings: 3,
    ),
    // Gold
    LoLRankInfo(
      name: 'Gold',
      arabicName: 'ذهبي',
      minXP: 600,
      maxXP: 999,
      colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
      gemColors: [Color(0xFFFFFacd), Color(0xFFFFE55C)],
      borderColor: Color(0xFFB8860B),
      accentColor: Color(0xFFFFD700),
      wings: 4,
    ),
    // Platinum
    LoLRankInfo(
      name: 'Platinum',
      arabicName: 'بلاتيني',
      minXP: 1000,
      maxXP: 1599,
      colors: [Color(0xFF00FFFF), Color(0xFF4682B4)],
      gemColors: [Color(0xFF87CEEB), Color(0xFF20B2AA)],
      borderColor: Color(0xFF4682B4),
      accentColor: Color(0xFF00FFFF),
      wings: 5,
    ),
    // Diamond
    LoLRankInfo(
      name: 'Diamond',
      arabicName: 'ماسي',
      minXP: 1600,
      maxXP: 2499,
      colors: [Color(0xFF3F48CC), Color(0xFF1E3A8A)],
      gemColors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
      borderColor: Color(0xFF1E3A8A),
      accentColor: Color(0xFF3B82F6),
      wings: 6,
    ),
    // Master
    LoLRankInfo(
      name: 'Master',
      arabicName: 'أستاذ',
      minXP: 2500,
      maxXP: 3999,
      colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
      gemColors: [Color(0xFFC084FC), Color(0xFFA855F7)],
      borderColor: Color(0xFF5B21B6),
      accentColor: Color(0xFF8B5CF6),
      wings: 7,
    ),
    // Grandmaster
    LoLRankInfo(
      name: 'Grandmaster',
      arabicName: 'أستاذ كبير',
      minXP: 4000,
      maxXP: 5999,
      colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
      gemColors: [Color(0xFFFF6B6B), Color(0xFFF87171)],
      borderColor: Color(0xFF991B1B),
      accentColor: Color(0xFFEF4444),
      wings: 8,
    ),
    // Challenger
    LoLRankInfo(
      name: 'Challenger',
      arabicName: 'متحدي',
      minXP: 6000,
      maxXP: 999999,
      colors: [Color(0xFFFFD700), Color(0xFFFF6B00)],
      gemColors: [Color(0xFFFFFFFF), Color(0xFFFFD700)],
      borderColor: Color(0xFFFF4500),
      accentColor: Color(0xFFFFD700),
      wings: 10,
    ),
  ];

  static LoLRankInfo getRankByName(String rankName) {
    return ranks.firstWhere(
      (rank) => rank.name == rankName,
      orElse: () => ranks.first,
    );
  }

  static LoLRankInfo getRankByXP(int xp) {
    return ranks.firstWhere(
      (rank) => xp >= rank.minXP && xp <= rank.maxXP,
      orElse: () => ranks.first,
    );
  }
}

class LoLRankBadge extends StatelessWidget {
  final String? rankName;
  final int? xp;
  final double size;
  final bool showName;

  const LoLRankBadge({
    super.key,
    this.rankName,
    this.xp,
    this.size = 100,
    this.showName = true,
  }) : assert(rankName != null || xp != null, 'Either rankName or xp must be provided');

  const LoLRankBadge.fromRank({
    super.key,
    required String rankName,
    this.size = 100,
    this.showName = true,
  }) : rankName = rankName,
       xp = null;

  const LoLRankBadge.fromXP({
    super.key,
    required int xp,
    this.size = 100,
    this.showName = true,
  }) : xp = xp,
       rankName = null;

  @override
  Widget build(BuildContext context) {
    final LoLRankInfo rank;
    
    if (rankName != null) {
      rank = LoLRankSystem.getRankByName(rankName!);
    } else {
      rank = LoLRankSystem.getRankByXP(xp!);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: size * 1.4,
                height: size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: rank.accentColor.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              
              // Wings/Side gems (LoL style)
              if (rank.wings > 0) ..._buildLoLWings(rank, size),
              
              // Main shield emblem
              _buildLoLMainShield(rank, size),
              
              // Center crystal/gem
              _buildLoLCenterGem(rank, size),
            ],
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 8),
          Text(
            rank.arabicName,
            style: TextStyle(
              fontSize: size * 0.15,
              fontWeight: FontWeight.bold,
              color: rank.accentColor,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Build LoL-style wings/gems around the emblem
  List<Widget> _buildLoLWings(LoLRankInfo rank, double size) {
    List<Widget> wings = [];
    
    for (int i = 0; i < rank.wings; i++) {
      final angle = (i * (360 / rank.wings)) * (pi / 180);
      final radius = size * 0.42;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      
      wings.add(
        Positioned(
          left: size * 0.5 + x - size * 0.06,
          top: size * 0.5 + y - size * 0.06,
          child: Container(
            width: size * 0.12,
            height: size * 0.18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: rank.gemColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.03),
                topRight: Radius.circular(size * 0.03),
                bottomLeft: Radius.circular(size * 0.01),
                bottomRight: Radius.circular(size * 0.01),
              ),
              border: Border.all(
                color: rank.borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: rank.accentColor.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(size * 0.008),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.8),
                    rank.gemColors.first.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.025),
                  topRight: Radius.circular(size * 0.025),
                  bottomLeft: Radius.circular(size * 0.005),
                  bottomRight: Radius.circular(size * 0.005),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return wings;
  }

  // Build LoL-style main shield
  Widget _buildLoLMainShield(LoLRankInfo rank, double size) {
    return Container(
      width: size * 0.6,
      height: size * 0.7,
      child: CustomPaint(
        painter: _LoLShieldPainter(rank, size),
      ),
    );
  }

  // Build LoL-style center gem
  Widget _buildLoLCenterGem(LoLRankInfo rank, double size) {
    return Container(
      width: size * 0.2,
      height: size * 0.2,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.white,
            rank.accentColor,
            rank.colors.last,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: rank.borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 12,
          ),
          BoxShadow(
            color: rank.accentColor.withOpacity(0.7),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.02),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.9),
              rank.accentColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Custom painter for LoL-style shield
class _LoLShieldPainter extends CustomPainter {
  final LoLRankInfo rank;
  final double size;
  
  _LoLShieldPainter(this.rank, this.size);
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;
    final shieldWidth = canvasSize.width * 0.8;
    final shieldHeight = canvasSize.height * 0.9;
    
    // Create LoL-style shield path
    final path = Path();
    
    // Top of shield (curved)
    path.moveTo(centerX, centerY - shieldHeight * 0.4);
    path.quadraticBezierTo(
      centerX - shieldWidth * 0.3, centerY - shieldHeight * 0.3,
      centerX - shieldWidth * 0.4, centerY - shieldHeight * 0.1,
    );
    
    // Left side
    path.lineTo(centerX - shieldWidth * 0.35, centerY + shieldHeight * 0.2);
    
    // Bottom point
    path.quadraticBezierTo(
      centerX - shieldWidth * 0.2, centerY + shieldHeight * 0.4,
      centerX, centerY + shieldHeight * 0.45,
    );
    
    // Right side (mirror)
    path.quadraticBezierTo(
      centerX + shieldWidth * 0.2, centerY + shieldHeight * 0.4,
      centerX + shieldWidth * 0.35, centerY + shieldHeight * 0.2,
    );
    
    path.lineTo(centerX + shieldWidth * 0.4, centerY - shieldHeight * 0.1);
    path.quadraticBezierTo(
      centerX + shieldWidth * 0.3, centerY - shieldHeight * 0.3,
      centerX, centerY - shieldHeight * 0.4,
    );
    
    path.close();
    
    // Draw shield background
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: rank.colors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height));
    
    canvas.drawPath(path, backgroundPaint);
    
    // Draw shield border
    final borderPaint = Paint()
      ..color = rank.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawPath(path, borderPaint);
    
    // Draw inner decorative lines (LoL style)
    final decorPaint = Paint()
      ..color = rank.accentColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Vertical center line
    canvas.drawLine(
      Offset(centerX, centerY - shieldHeight * 0.3),
      Offset(centerX, centerY + shieldHeight * 0.3),
      decorPaint,
    );
    
    // Horizontal lines
    for (int i = 1; i <= 3; i++) {
      final y = centerY - shieldHeight * 0.2 + (i * shieldHeight * 0.15);
      final lineWidth = shieldWidth * (0.6 - i * 0.1);
      canvas.drawLine(
        Offset(centerX - lineWidth * 0.3, y),
        Offset(centerX + lineWidth * 0.3, y),
        decorPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated version for special effects
class AnimatedLoLRankBadge extends StatefulWidget {
  final String? rankName;
  final int? xp;
  final double size;
  final bool showName;

  const AnimatedLoLRankBadge({
    super.key,
    this.rankName,
    this.xp,
    this.size = 100,
    this.showName = true,
  }) : assert(rankName != null || xp != null, 'Either rankName or xp must be provided');

  const AnimatedLoLRankBadge.fromRank({
    super.key,
    required String rankName,
    this.size = 100,
    this.showName = true,
  }) : rankName = rankName,
       xp = null;

  @override
  State<AnimatedLoLRankBadge> createState() => _AnimatedLoLRankBadgeState();
}

class _AnimatedLoLRankBadgeState extends State<AnimatedLoLRankBadge>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LoLRankInfo rank;
    
    if (widget.rankName != null) {
      rank = LoLRankSystem.getRankByName(widget.rankName!);
    } else {
      rank = LoLRankSystem.getRankByXP(widget.xp!);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_glowController, _rotationController]),
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated outer glow
                  Container(
                    width: widget.size * 1.5,
                    height: widget.size * 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: rank.accentColor.withOpacity(_glowAnimation.value * 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  
                  // Rotating wings for higher ranks
                  if (rank.wings > 4)
                    Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        child: Stack(
                          children: _buildLoLWings(rank, widget.size),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: widget.size,
                      height: widget.size,
                      child: Stack(
                        children: _buildLoLWings(rank, widget.size),
                      ),
                    ),
                  
                  // Main shield
                  _buildLoLMainShield(rank, widget.size),
                  
                  // Animated center gem
                  Transform.scale(
                    scale: 1.0 + (_glowAnimation.value - 0.7) * 0.1,
                    child: _buildLoLCenterGem(rank, widget.size),
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.showName) ...[
          const SizedBox(height: 8),
          Text(
            rank.arabicName,
            style: TextStyle(
              fontSize: widget.size * 0.15,
              fontWeight: FontWeight.bold,
              color: rank.accentColor,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Build LoL-style wings/gems
  List<Widget> _buildLoLWings(LoLRankInfo rank, double size) {
    List<Widget> wings = [];
    
    for (int i = 0; i < rank.wings; i++) {
      final angle = (i * (360 / rank.wings)) * (pi / 180);
      final radius = size * 0.35;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      
      wings.add(
        Positioned(
          left: size * 0.5 + x - size * 0.05,
          top: size * 0.5 + y - size * 0.08,
          child: Transform.rotate(
            angle: angle + pi / 2,
            child: Container(
              width: size * 0.1,
              height: size * 0.16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: rank.gemColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.02),
                  topRight: Radius.circular(size * 0.02),
                  bottomLeft: Radius.circular(size * 0.005),
                  bottomRight: Radius.circular(size * 0.005),
                ),
                border: Border.all(
                  color: rank.borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: rank.accentColor.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return wings;
  }

  // Build LoL-style main shield
  Widget _buildLoLMainShield(LoLRankInfo rank, double size) {
    return Container(
      width: size * 0.5,
      height: size * 0.6,
      child: CustomPaint(
        painter: _LoLShieldPainter(rank, size),
      ),
    );
  }

  // Build LoL-style center gem
  Widget _buildLoLCenterGem(LoLRankInfo rank, double size) {
    return Container(
      width: size * 0.18,
      height: size * 0.18,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.white,
            rank.accentColor.withOpacity(0.9),
            rank.colors.last,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: rank.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
          ),
          BoxShadow(
            color: rank.accentColor.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}