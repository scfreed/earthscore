import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_score.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Immutable snapshot of the in-progress game.
// ─────────────────────────────────────────────────────────────────────────────

class ScoringSession {
  final String gameId;
  final String gameName;
  final DateTime date;
  final String notes;
  final List<String> playerIds; // tab order
  final Map<String, PlayerScore> scores; // playerId → score

  const ScoringSession({
    required this.gameId,
    required this.gameName,
    required this.date,
    required this.notes,
    required this.playerIds,
    required this.scores,
  });

  bool get isEmpty => playerIds.isEmpty;

  PlayerScore scoreFor(String playerId) =>
      scores[playerId] ?? PlayerScore(playerId: playerId);

  ScoringSession copyWith({
    String? gameId,
    String? gameName,
    DateTime? date,
    String? notes,
    List<String>? playerIds,
    Map<String, PlayerScore>? scores,
  }) {
    return ScoringSession(
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      playerIds: playerIds ?? this.playerIds,
      scores: scores ?? this.scores,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ScoringSessionNotifier extends StateNotifier<ScoringSession?> {
  ScoringSessionNotifier() : super(null);

  /// Called from New Game screen to initialise a fresh session.
  void startSession({
    required String gameId,
    required String gameName,
    required DateTime date,
    required String notes,
    required List<String> playerIds,
  }) {
    state = ScoringSession(
      gameId: gameId,
      gameName: gameName,
      date: date,
      notes: notes,
      playerIds: playerIds,
      scores: {
        for (final id in playerIds) id: PlayerScore(playerId: id),
      },
    );
  }

  /// Update a single integer field on one player's score.
  void updateField(String playerId, String field, int value) {
    if (state == null) return;
    final current = state!.scoreFor(playerId);
    final updated = _applyInt(current, field, value);
    _updateScore(playerId, updated);
  }

  /// Toggle the firstTableauComplete checkbox.
  void toggleFirstTableau(String playerId, bool value) {
    if (state == null) return;
    final current = state!.scoreFor(playerId);
    _updateScore(playerId, current.copyWith(firstTableauComplete: value));
  }

  /// Set the free-text other note.
  void updateOtherNote(String playerId, String note) {
    if (state == null) return;
    final current = state!.scoreFor(playerId);
    _updateScore(playerId, current.copyWith(otherNote: note));
  }

  void updateGameMeta({String? name, DateTime? date, String? notes}) {
    if (state == null) return;
    state = state!.copyWith(
      gameName: name ?? state!.gameName,
      date: date ?? state!.date,
      notes: notes ?? state!.notes,
    );
  }

  void clearSession() => state = null;

  // ── Private helpers ───────────────────────────────────────────────────────

  void _updateScore(String playerId, PlayerScore updated) {
    final newScores = Map<String, PlayerScore>.from(state!.scores);
    newScores[playerId] = updated;
    state = state!.copyWith(scores: newScores);
  }

  static PlayerScore _applyInt(PlayerScore s, String field, int v) {
    switch (field) {
      case 'islandCardVp':      return s.copyWith(islandCardVp: v);
      case 'climateCardVp':     return s.copyWith(climateCardVp: v);
      case 'tableauCardsVp':    return s.copyWith(tableauCardsVp: v);
      case 'eventsVp':          return s.copyWith(eventsVp: v);
      case 'terrainVp':         return s.copyWith(terrainVp: v);
      case 'compostCards':      return s.copyWith(compostCards: v);
      case 'sproutsRemaining':  return s.copyWith(sproutsRemaining: v);
      case 'growthVp':          return s.copyWith(growthVp: v);
      case 'personalEcosystemVp': return s.copyWith(personalEcosystemVp: v);
      case 'sharedEcosystemVp': return s.copyWith(sharedEcosystemVp: v);
      case 'faunaBoardVp':      return s.copyWith(faunaBoardVp: v);
      case 'firstTableauBonusVp': return s.copyWith(firstTableauBonusVp: v);
      case 'otherVp':           return s.copyWith(otherVp: v);
      default:                  return s;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

final scoringSessionProvider =
    StateNotifierProvider<ScoringSessionNotifier, ScoringSession?>((ref) {
  return ScoringSessionNotifier();
});

/// Live score for a specific player in the active session.
final playerLiveScoreProvider = Provider.family<PlayerScore?, String>((ref, id) {
  final session = ref.watch(scoringSessionProvider);
  return session?.scoreFor(id);
});

/// Live running total for a specific player.
final playerLiveTotalProvider = Provider.family<int, String>((ref, id) {
  final score = ref.watch(playerLiveScoreProvider(id));
  return score?.total ?? 0;
});
