import 'package:flutter/material.dart';
import 'dart:math';

class RankInfo {
  final String name;
  final String arabicName;
  final int minXP;
  final int maxXP;
  final List<Color> colors;
  final List<Color> gemColors;
  final Color borderColor;
  final Color accentColor;
  final int gems; // Number of gems/wings in the design

  const RankInfo({
    required this.name,
    required this.arabicName,
    required this.minXP,
    required this.maxXP,
    required this.colors,
    required this.gemColors,
    required this.borderColor,
    required this.accentColor,
    required this.gems,
  });
}

class RankSystem {
  static const List<RankInfo> ranks = [
    // Iron (like LoL Bronze)
    RankInfo(
      name: 'Iron',
      arabicName: 'حديدي',
      minXP: 0,
      maxXP: 99,
      colors: [Color(0xFF4A4A4A), Color(0xFF2C2C2C)],
      gemColors: [Color(0xFF666666), Color(0xFF444444)],
      borderColor: Color(0xFF2C2C2C),
      accentColor: Color(0xFF666666),
      gems: 0,
    ),
    // Bronze
    RankInfo(
      name: 'Bronze',
      arabicName: 'برونزي',
      minXP: 100,
      maxXP: 299,
      colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
      gemColors: [Color(0xFFB8860B), Color(0xFF8B4513)],
      borderColor: Color(0xFF8B4513),
      accentColor: Color(0xFFD2691E),
      gems: 1,
    ),
    // Silver
    RankInfo(
      name: 'Silver',
      arabicName: 'فضي',
      minXP: 300,
      maxXP: 599,
      colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
      gemColors: [Color(0xFFE6E6FA), Color(0xFFC0C0C0)],
      borderColor: Color(0xFF696969),
      accentColor: Color(0xFFDCDCDC),
      gems: 2,
    ),
    // Gold
    RankInfo(
      name: 'Gold',
      arabicName: 'ذهبي',
      minXP: 600,
      maxXP: 999,
      colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
      gemColors: [Color(0xFFFFFacd), Color(0xFFFFD700)],
      borderColor: Color(0xFFB8860B),
      accentColor: Color(0xFFFFD700),
      gems: 3,
    ),
    // Platinum
    RankInfo(
      name: 'Platinum',
      arabicName: 'بلاتيني',
      minXP: 1000,
      maxXP: 1599,
      colors: [Color(0xFF00FFFF), Color(0xFF4682B4)],
      gemColors: [Color(0xFF87CEEB), Color(0xFF00CED1)],
      borderColor: Color(0xFF4682B4),
      accentColor: Color(0xFF00FFFF),
      gems: 4,
    ),
    // Diamond
    RankInfo(
      name: 'Diamond',
      arabicName: 'ماسي',
      minXP: 1600,
      maxXP: 2499,
      colors: [Color(0xFF3F48CC), Color(0xFF1E3A8A)],
      gemColors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
      borderColor: Color(0xFF1E3A8A),
      accentColor: Color(0xFF60A5FA),
      gems: 5,
    ),
    // Master
    RankInfo(
      name: 'Master',
      arabicName: 'أستاذ',
      minXP: 2500,
      maxXP: 3999,
      colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
      gemColors: [Color(0xFFC084FC), Color(0xFF8B5CF6)],
      borderColor: Color(0xFF5B21B6),
      accentColor: Color(0xFFA855F7),
      gems: 6,
    ),
    // Grandmaster
    RankInfo(
      name: 'Grandmaster',
      arabicName: 'أستاذ كبير',
      minXP: 4000,
      maxXP: 5999,
      colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
      gemColors: [Color(0xFFFF6B6B), Color(0xFFDC2626)],
      borderColor: Color(0xFF991B1B),
      accentColor: Color(0xFFEF4444),
      gems: 7,
    ),
    // Challenger
    RankInfo(
      name: 'Challenger',
      arabicName: 'متحدي',
      minXP: 6000,
      maxXP: 999999,
      colors: [Color(0xFFFFD700), Color(0xFFFF6B00), Color(0xFFFF1493)],
      gemColors: [Color(0xFFFFFFFF), Color(0xFFFFD700), Color(0xFFFF69B4)],
      borderColor: Color(0xFFFF6B00),
      accentColor: Color(0xFFFFD700),
      gems: 8,
    ),
  ];

  static RankInfo getRankByXP(int xp) {
    return ranks.firstWhere(
      (rank) => xp >= rank.minXP && xp <= rank.maxXP,
      orElse: () => ranks.first,
    );
  }

  static RankInfo getRankByName(String rankName) {
    return ranks.firstWhere(
      (rank) => rank.name == rankName,
      orElse: () => ranks.first,
    );
  }

  static RankInfo? getNextRank(int xp) {
    final currentRank = getRankByXP(xp);
    final currentIndex = ranks.indexOf(currentRank);
    if (currentIndex < ranks.length - 1) {
      return ranks[currentIndex + 1];
    }
    return null;
  }

  static double getProgressToNextRank(int xp) {
    final currentRank = getRankByXP(xp);
    final nextRank = getNextRank(xp);
    
    if (nextRank == null) return 1.0; // Max rank reached
    
    final progressInCurrentRank = xp - currentRank.minXP;
    final totalXPNeeded = nextRank.minXP - currentRank.minXP;
    
    return (progressInCurrentRank / totalXPNeeded).clamp(0.0, 1.0);
  }
}

class RankBadge extends StatelessWidget {
  final int? xp;
  final String? rankName;
  final double size;
  final bool showName;
  final bool showXP;

  const RankBadge({
    super.key,
    this.xp,
    this.rankName,
    this.size = 80,
    this.showName = true,
    this.showXP = false,
  }) : assert(xp != null || rankName != null, 'Either xp or rankName must be provided');

  const RankBadge.fromXP({
    super.key,
    required int xp,
    this.size = 80,
    this.showName = true,
    this.showXP = false,
  }) : xp = xp,
       rankName = null;

  const RankBadge.fromRank({
    super.key,
    required String rankName,
    this.size = 80,
    this.showName = true,
    this.showXP = false,
  }) : rankName = rankName,
       xp = null;

  String _getRankSymbol(int rankIndex) {
    switch (rankIndex) {
      case 0: return 'Fe'; // Iron
      case 1: return 'Br'; // Bronze  
      case 2: return 'Ag'; // Silver
      case 3: return 'Au'; // Gold
      case 4: return 'Pt'; // Platinum
      case 5: return '💎'; // Diamond
      case 6: return 'M'; // Master
      case 7: return 'GM'; // Grandmaster
      case 8: return '👑'; // Challenger
      default: return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final RankInfo rank;
    final double progress;
    final RankInfo? nextRank;
    
    if (rankName != null) {
      rank = RankSystem.getRankByName(rankName!);
      progress = 0.0; // Don't show progress when using rank name directly
      nextRank = null;
    } else {
      rank = RankSystem.getRankByXP(xp!);
      progress = RankSystem.getProgressToNextRank(xp!);
      nextRank = RankSystem.getNextRank(xp!);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rank Badge
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow effect
            Container(
              width: size * 1.2,
              height: size * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: rank.colors.first.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Main badge with detailed design
            _buildDetailedBadge(rank, size),
          ],
        ),
        if (showName) ...[
          const SizedBox(height: 8),
          Text(
            rank.arabicName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: rank.colors.first,
            ),
          ),
        ],
        if (showXP && xp != null) ...[
          const SizedBox(height: 4),
          Text(
            '$xp XP',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (nextRank != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: size,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(rank.colors.first),
                    minHeight: 4,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${nextRank.minXP - (xp ?? 0)} XP to ${nextRank.arabicName}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDetailedBadge(RankInfo rank, double size) {
    final rankIndex = RankSystem.ranks.indexOf(rank);
    
    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  rank.colors.first.withOpacity(0.8),
                  rank.colors.last.withOpacity(0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
          // Inner decorative ring
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: rank.borderColor.withOpacity(0.6),
                width: 2,
              ),
            ),
          ),
          // Main badge container
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: rank.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: rank.borderColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: rank.colors.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background pattern for higher ranks
                if (rankIndex >= 2) 
                  Container(
                    width: size * 0.7,
                    height: size * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _RankPatternPainter(rank.colors.first),
                    ),
                  ),
                
                // Main icon with enhanced styling
                Container(
                  padding: EdgeInsets.all(size * 0.1),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rank symbol text
                      Text(
                        _getRankSymbol(rankIndex),
                        style: TextStyle(
                          fontSize: size * 0.35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                            Shadow(
                              color: rank.colors.first.withOpacity(0.5),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                      // Special overlay for Challenger
                      if (rankIndex == 7)
                        Icon(
                          Icons.whatshot,
                          size: size * 0.25,
                          color: Colors.white.withOpacity(0.8),
                        ),
                    ],
                  ),
                ),
                
                // Decorative elements based on rank
                ..._buildRankDecorations(rank, size, rankIndex),
              ],
            ),
          ),
        ],
      ),
    );
  }


  List<Widget> _buildRankDecorations(RankInfo rank, double size, int rankIndex) {
    List<Widget> decorations = [];
    
    // Bronze: Simple design
    if (rankIndex == 0) {
      // No extra decorations for bronze
    }
    
    // Silver: Add some shine
    else if (rankIndex == 1) {
      decorations.addAll([
        Positioned(
          top: size * 0.15,
          right: size * 0.25,
          child: Container(
            width: size * 0.08,
            height: size * 0.08,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ]);
    }
    
    // Gold: Add crown elements
    else if (rankIndex == 2) {
      decorations.addAll([
        Positioned(
          top: size * 0.1,
          child: Icon(
            Icons.keyboard_arrow_up,
            size: size * 0.2,
            color: Colors.yellow.shade700,
          ),
        ),
      ]);
    }
    
    // Platinum: Add geometric patterns
    else if (rankIndex == 3) {
      for (int i = 0; i < 6; i++) {
        final angle = (i * 60) * (3.14159 / 180);
        final x = size * 0.35 * cos(angle);
        final y = size * 0.35 * sin(angle);
        decorations.add(
          Positioned(
            left: size * 0.5 + x - size * 0.03,
            top: size * 0.5 + y - size * 0.03,
            child: Container(
              width: size * 0.06,
              height: size * 0.06,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }
    }
    
    // Diamond: Add diamond sparkles
    else if (rankIndex == 4) {
      decorations.addAll([
        ...List.generate(8, (i) {
          final angle = (i * 45) * (3.14159 / 180);
          final radius = size * 0.32;
          final x = radius * cos(angle);
          final y = radius * sin(angle);
          return Positioned(
            left: size * 0.5 + x - size * 0.025,
            top: size * 0.5 + y - size * 0.025,
            child: Icon(
              Icons.star,
              size: size * 0.1,
              color: Colors.cyan.shade200,
            ),
          );
        }),
      ]);
    }
    
    // Master: Add crown and stars
    else if (rankIndex == 5) {
      decorations.addAll([
        Positioned(
          top: size * 0.05,
          child: Icon(
            Icons.star,
            size: size * 0.18,
            color: Colors.yellow,
          ),
        ),
        Positioned(
          top: size * 0.12,
          left: size * 0.15,
          child: Icon(
            Icons.star,
            size: size * 0.12,
            color: Colors.yellow.shade700,
          ),
        ),
        Positioned(
          top: size * 0.12,
          right: size * 0.15,
          child: Icon(
            Icons.star,
            size: size * 0.12,
            color: Colors.yellow.shade700,
          ),
        ),
      ]);
    }
    
    // Grandmaster: Multiple crowns and effects
    else if (rankIndex == 6) {
      decorations.addAll([
        Positioned(
          top: size * 0.02,
          child: Icon(
            Icons.stars,
            size: size * 0.25,
            color: Colors.amber,
          ),
        ),
        Positioned(
          bottom: size * 0.02,
          child: Icon(
            Icons.auto_awesome,
            size: size * 0.15,
            color: Colors.red.shade300,
          ),
        ),
        ...List.generate(12, (i) {
          final angle = (i * 30) * (3.14159 / 180);
          final radius = size * 0.38;
          final x = radius * cos(angle);
          final y = radius * sin(angle);
          return Positioned(
            left: size * 0.5 + x - size * 0.015,
            top: size * 0.5 + y - size * 0.015,
            child: Container(
              width: size * 0.03,
              height: size * 0.03,
              decoration: BoxDecoration(
                color: i.isEven ? Colors.red.shade400 : Colors.yellow.shade600,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ]);
    }
    
    // Challenger: Ultimate design with particles and multiple effects
    else if (rankIndex == 7) {
      decorations.addAll([
        // Rotating particles
        ...List.generate(16, (i) {
          final angle = (i * 22.5) * (3.14159 / 180);
          final radius = size * 0.4;
          final x = radius * cos(angle);
          final y = radius * sin(angle);
          return Positioned(
            left: size * 0.5 + x - size * 0.02,
            top: size * 0.5 + y - size * 0.02,
            child: Container(
              width: size * 0.04,
              height: size * 0.04,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow, Colors.orange, Colors.pink],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          );
        }),
        // Central crown
        Positioned(
          top: size * 0.08,
          child: Icon(
            Icons.diamond,
            size: size * 0.2,
            color: Colors.yellow,
            shadows: [
              Shadow(
                color: Colors.orange.withOpacity(0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        // Lightning effects
        Positioned(
          bottom: size * 0.08,
          left: size * 0.15,
          child: Icon(
            Icons.flash_on,
            size: size * 0.15,
            color: Colors.cyan,
          ),
        ),
        Positioned(
          bottom: size * 0.08,
          right: size * 0.15,
          child: Icon(
            Icons.flash_on,
            size: size * 0.15,
            color: Colors.pink,
          ),
        ),
      ]);
    }
    
    return decorations;
  }
}

// Custom painter for background patterns
class _RankPatternPainter extends CustomPainter {
  final Color color;
  
  _RankPatternPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 4), paint);
    }
    
    // Draw radial lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final start = Offset(
        center.dx + (radius * 0.3) * cos(angle),
        center.dy + (radius * 0.3) * sin(angle),
      );
      final end = Offset(
        center.dx + (radius * 0.8) * cos(angle),
        center.dy + (radius * 0.8) * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedRankBadge extends StatefulWidget {
  final int? xp;
  final String? rankName;
  final double size;
  final bool showName;
  final bool showXP;

  const AnimatedRankBadge({
    super.key,
    this.xp,
    this.rankName,
    this.size = 80,
    this.showName = true,
    this.showXP = false,
  }) : assert(xp != null || rankName != null, 'Either xp or rankName must be provided');

  const AnimatedRankBadge.fromXP({
    super.key,
    required int xp,
    this.size = 80,
    this.showName = true,
    this.showXP = false,
  }) : xp = xp,
       rankName = null;

  const AnimatedRankBadge.fromRank({
    super.key,
    required String rankName,
    this.size = 80,
    this.showName = true,
    this.showXP = false,
  }) : rankName = rankName,
       xp = null;

  @override
  State<AnimatedRankBadge> createState() => _AnimatedRankBadgeState();
}

class _AnimatedRankBadgeState extends State<AnimatedRankBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: RankBadge(
              xp: widget.xp,
              rankName: widget.rankName,
              size: widget.size,
              showName: widget.showName,
              showXP: widget.showXP,
            ),
          ),
        );
      },
    );
  }
}