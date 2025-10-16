import 'app_localizations.dart';

extension AppLocalizationsExtension on AppLocalizations {
  String getLocalizedRankName(String rank) {
    switch (rank.toLowerCase()) {
      case 'iron':
        return rankIron;
      case 'bronze':
        return rankBronze;
      case 'silver':
        return rankSilver;
      case 'gold':
        return rankGold;
      case 'platinum':
        return rankPlatinum;
      case 'emerald':
        return rankEmerald;
      case 'diamond':
        return rankDiamond;
      case 'master':
        return rankMaster;
      case 'grandmaster':
        return rankGrandmaster;
      case 'challenger':
        return rankChallenger;
      default:
        return rank; // Return original rank if not found
    }
  }
}