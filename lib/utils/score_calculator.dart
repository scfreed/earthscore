import '../models/game.dart';
import '../models/player.dart';
import '../models/player_score.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pure scoring helpers — no Flutter, no Riverpod, easy to unit-test.
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the rank (1-based) of [playerId] in [game].
/// Tied players share the same rank.
int rankOf(Game game, String playerId) {
  final ranked = game.rankedScores;
  final myScore = game.scoreFor(playerId)?.total ?? 0;
  // rank = number of players who scored strictly more + 1
  return ranked.where((s) => s.total > myScore).length + 1;
}

/// Returns a map of playerId → rank for every player in [game].
Map<String, int> rankMap(Game game) {
  return {for (final s in game.scores) s.playerId: rankOf(game, s.playerId)};
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-player statistics across a list of saved games.
// ─────────────────────────────────────────────────────────────────────────────

class PlayerStats {
  final String playerId;
  final int gamesPlayed;
  final int wins;          // sole first-place finishes
  final int ties;          // tied-first finishes
  final double winRate;    // (wins + ties) / gamesPlayed
  final double avgScore;
  final int highScore;
  final int lowScore;

  const PlayerStats({
    required this.playerId,
    required this.gamesPlayed,
    required this.wins,
    required this.ties,
    required this.winRate,
    required this.avgScore,
    required this.highScore,
    required this.lowScore,
  });
}

PlayerStats computeStats(Player player, List<Game> allGames) {
  final myGames =
      allGames.where((g) => g.playerIds.contains(player.id)).toList();

  if (myGames.isEmpty) {
    return PlayerStats(
      playerId: player.id,
      gamesPlayed: 0,
      wins: 0,
      ties: 0,
      winRate: 0,
      avgScore: 0,
      highScore: 0,
      lowScore: 0,
    );
  }

  int wins = 0;
  int ties = 0;
  final scores = <int>[];

  for (final game in myGames) {
    final score = game.scoreFor(player.id);
    if (score != null) scores.add(score.total);

    final winners = game.winnerIds;
    if (winners.contains(player.id)) {
      if (winners.length == 1) {
        wins++;
      } else {
        ties++;
      }
    }
  }

  final total = scores.fold(0, (a, b) => a + b);

  return PlayerStats(
    playerId: player.id,
    gamesPlayed: myGames.length,
    wins: wins,
    ties: ties,
    winRate: (wins + ties) / myGames.length,
    avgScore: scores.isEmpty ? 0 : total / scores.length,
    highScore: scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b),
    lowScore: scores.isEmpty ? 0 : scores.reduce((a, b) => a < b ? a : b),
  );
}

/// Category-level breakdown for a single game score — useful for the
/// detail screen bar charts.
Map<String, int> categoryBreakdown(PlayerScore s) => {
      'Cards': s.cardsVp,
      'Sprouts': s.sproutsVp,
      'Trunks': s.trunksVp,
      'Canopy': s.canopyVp,
      'Terrain': s.terrainVp,
      'Personal Eco': s.personalEcoVp,
      'Shared Eco': s.sharedEcoVp,
      'Compost': s.compostCards,
      'Events': s.eventsVp,
      'Fauna Board': s.faunaBoardVp,
    };
