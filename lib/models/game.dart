import 'player_score.dart';

class Game {
  final String id;
  final String name;
  final int dateMs; // milliseconds since epoch
  final String notes;
  final List<String> playerIds; // ordered — determines tab order in scoring
  final List<PlayerScore> scores;

  const Game({
    required this.id,
    required this.name,
    required this.dateMs,
    required this.notes,
    required this.playerIds,
    required this.scores,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateMs);

  /// Returns the player IDs that tied for first place.
  List<String> get winnerIds {
    if (scores.isEmpty) return [];
    final maxScore = scores.map((s) => s.total).reduce((a, b) => a > b ? a : b);
    return scores.where((s) => s.total == maxScore).map((s) => s.playerId).toList();
  }

  bool get hasWinner => winnerIds.length == 1;

  /// Scores sorted descending.
  List<PlayerScore> get rankedScores {
    final sorted = List<PlayerScore>.from(scores);
    sorted.sort((a, b) => b.total.compareTo(a.total));
    return sorted;
  }

  PlayerScore? scoreFor(String playerId) {
    try {
      return scores.firstWhere((s) => s.playerId == playerId);
    } catch (_) {
      return null;
    }
  }

  Game copyWith({
    String? id,
    String? name,
    int? dateMs,
    String? notes,
    List<String>? playerIds,
    List<PlayerScore>? scores,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      dateMs: dateMs ?? this.dateMs,
      notes: notes ?? this.notes,
      playerIds: playerIds ?? this.playerIds,
      scores: scores ?? this.scores,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dateMs': dateMs,
        'notes': notes,
        'playerIds': playerIds,
        'scores': scores.map((s) => s.toMap()).toList(),
      };

  factory Game.fromMap(Map<dynamic, dynamic> map) => Game(
        id: map['id'] as String,
        name: map['name'] as String,
        dateMs: map['dateMs'] as int,
        notes: (map['notes'] as String?) ?? '',
        playerIds: (map['playerIds'] as List).cast<String>(),
        scores: (map['scores'] as List)
            .map((s) => PlayerScore.fromMap(s as Map))
            .toList(),
      );
}
