# Min el Gasos - Ranking System Documentation

## Overview
The ranking system has been successfully implemented with XP-based progression, role-specific bonuses, and visual rank indicators. Players earn XP by playing games, with additional bonuses for winning and role performance.

## XP Calculation System

### Base XP Values
- **Win as Spy**: 65 XP (50 base + 15 spy bonus)
- **Win as Detective**: 45 XP
- **Loss**: 15 XP (participation reward)
- **Loss as Spy**: 20 XP (extra 5 XP for difficulty)

### Bonus XP
- **Win Streak Bonus**: +10 XP per 3 consecutive wins
- **First Win of the Day**: +25 XP
- **Maximum possible XP per game**: ~100 XP (with all bonuses)

## Ranking Tiers

| Rank | XP Range | Badge Color | Symbol |
|------|----------|-------------|--------|
| Iron | 0-99 | Gray | Fe |
| Bronze | 100-299 | Brown | Br |
| Silver | 300-599 | Silver | Ag |
| Gold | 600-999 | Gold | Au |
| Platinum | 1000-1599 | Cyan | Pt |
| Diamond | 1600-2499 | Blue | 💎 |
| Master | 2500-3999 | Purple | M |
| Grandmaster | 4000-5999 | Red | GM |
| Challenger | 6000+ | Rainbow | 👑 |

## Implementation Components

### 1. GameStatsService (`lib/services/game_stats_service.dart`)
- Handles XP calculation with role-based bonuses
- Records game results to Firebase
- Tracks win streaks and daily bonuses
- Manages game history (keeps last 50 games)
- Provides leaderboard functionality

### 2. Game Result Capture (`lib/screens/game_timer_screen.dart`)
- Shows "Who Won?" dialog after game ends
- Players select winning team (Spies or Detectives)
- Player identifies themselves from numbered list
- Displays XP gained with animations
- Shows rank-up celebrations when advancing

### 3. User Statistics Tracking
Firebase document structure:
```json
{
  "xp": 0,
  "rank": "Iron",
  "stats": {
    "gamesPlayed": 0,
    "wins": 0,
    "losses": 0,
    "spyWins": 0,
    "detectiveWins": 0,
    "winStreak": 0,
    "winRate": "0.0"
  }
}
```

### 4. Visual Components
- **RankBadge**: Displays current rank with progress bar
- **RankEmblemPNG**: League of Legends-style rank emblems
- **Rank-up animations**: Celebratory dialog with old → new rank transition

## Progression Timeline (Moderate Difficulty)

### Casual Player (2-3 games/day, 40% win rate)
- **Iron → Bronze**: ~3-4 days
- **Bronze → Silver**: ~7-10 days
- **Silver → Gold**: ~2 weeks
- **Gold → Platinum**: ~3 weeks
- **Platinum → Diamond**: ~1 month
- **Diamond → Master**: ~1.5 months
- **Master → Grandmaster**: ~2 months
- **Grandmaster → Challenger**: ~2-3 months

### Active Player (5-7 games/day, 50% win rate)
- **Iron → Gold**: ~1 week
- **Gold → Diamond**: ~2-3 weeks
- **Diamond → Challenger**: ~2-3 months

### Competitive Player (10+ games/day, 60% win rate, spy main)
- **Iron → Diamond**: ~10 days
- **Diamond → Challenger**: ~1 month

## Features Implemented

✅ **Core Ranking Logic**
- XP calculation with role bonuses
- Automatic rank progression
- Win streak tracking
- First win of the day bonus

✅ **Game Integration**
- Post-game result capture
- Player identification system
- XP gain notifications
- Rank-up celebrations

✅ **Data Persistence**
- Firebase Firestore integration
- Game history tracking
- Statistics updates
- Offline game support

✅ **Visual Feedback**
- Animated rank badges
- Progress indicators
- XP gain dialogs
- Rank transition effects

## Future Enhancements (Optional)

1. **Seasonal Resets**
   - Quarterly rank resets with rewards
   - Season-specific badges
   - Historical rank tracking

2. **Achievements**
   - "Spy Master" - Win 100 games as spy
   - "Detective Elite" - Win 100 games as detective
   - "Unstoppable" - 10 game win streak

3. **Leaderboards**
   - Global rankings
   - Friend rankings
   - Regional competitions

4. **Advanced Statistics**
   - Role-specific win rates
   - Performance trends
   - Detailed match history

## Testing the System

The ranking system is fully functional and ready for testing:

1. Play a game and reach the voting phase
2. Click "Result" button
3. Select winning team
4. Choose your player number
5. View XP gained and potential rank-up

The system automatically handles:
- Anonymous players (no Firebase login)
- Network failures (graceful degradation)
- Data synchronization (when online)
- Progress persistence (across sessions)