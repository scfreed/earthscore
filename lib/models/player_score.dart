/// One player's complete score for a single game.
/// Fields match the 10 columns on the Earth scoresheet, in scoresheet order.
/// The [total] getter sums every column.
class PlayerScore {
  final String playerId;

  // ── Col 1: Base card VP ───────────────────────────────────────────────────
  int cardsVp;          // Island + Climate + all Tableau cards (not Events/hand/Compost)

  // ── Col 2–4: Growth tokens ────────────────────────────────────────────────
  int sproutsVp;        // Sprout tokens in tableau          (×1 VP each)
  int trunksVp;         // Trunk tokens in tableau           (×1 VP each, see canopy rule)
  int canopyVp;         // Canopy completion VP

  // ── Col 5: Terrain ────────────────────────────────────────────────────────
  int terrainVp;        // End-game bonus from Terrain cards

  // ── Col 6–7: Ecosystem objectives ─────────────────────────────────────────
  int personalEcoVp;    // Personal Ecosystem objective
  int sharedEcoVp;      // Both shared Ecosystem objectives combined

  // ── Col 8: Compost ────────────────────────────────────────────────────────
  int compostCards;     // Cards in Compost pile             (×1 VP each)

  // ── Col 9: Events ─────────────────────────────────────────────────────────
  int eventsVp;         // Base VP from Event space (can be negative)

  // ── Col 10: Fauna Board ───────────────────────────────────────────────────
  int faunaBoardVp;     // Leaf tokens placed on the Fauna board

  PlayerScore({
    required this.playerId,
    this.cardsVp = 0,
    this.sproutsVp = 0,
    this.trunksVp = 0,
    this.canopyVp = 0,
    this.terrainVp = 0,
    this.personalEcoVp = 0,
    this.sharedEcoVp = 0,
    this.compostCards = 0,
    this.eventsVp = 0,
    this.faunaBoardVp = 0,
  });

  int get total =>
      cardsVp +
      sproutsVp +
      trunksVp +
      canopyVp +
      terrainVp +
      personalEcoVp +
      sharedEcoVp +
      compostCards +
      eventsVp +
      faunaBoardVp;

  PlayerScore copyWith({
    String? playerId,
    int? cardsVp,
    int? sproutsVp,
    int? trunksVp,
    int? canopyVp,
    int? terrainVp,
    int? personalEcoVp,
    int? sharedEcoVp,
    int? compostCards,
    int? eventsVp,
    int? faunaBoardVp,
  }) {
    return PlayerScore(
      playerId: playerId ?? this.playerId,
      cardsVp: cardsVp ?? this.cardsVp,
      sproutsVp: sproutsVp ?? this.sproutsVp,
      trunksVp: trunksVp ?? this.trunksVp,
      canopyVp: canopyVp ?? this.canopyVp,
      terrainVp: terrainVp ?? this.terrainVp,
      personalEcoVp: personalEcoVp ?? this.personalEcoVp,
      sharedEcoVp: sharedEcoVp ?? this.sharedEcoVp,
      compostCards: compostCards ?? this.compostCards,
      eventsVp: eventsVp ?? this.eventsVp,
      faunaBoardVp: faunaBoardVp ?? this.faunaBoardVp,
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'cardsVp': cardsVp,
        'sproutsVp': sproutsVp,
        'trunksVp': trunksVp,
        'canopyVp': canopyVp,
        'terrainVp': terrainVp,
        'personalEcoVp': personalEcoVp,
        'sharedEcoVp': sharedEcoVp,
        'compostCards': compostCards,
        'eventsVp': eventsVp,
        'faunaBoardVp': faunaBoardVp,
      };

  factory PlayerScore.fromMap(Map<dynamic, dynamic> map) => PlayerScore(
        playerId: map['playerId'] as String,
        cardsVp: (map['cardsVp'] as int?) ?? 0,
        sproutsVp: (map['sproutsVp'] as int?) ?? 0,
        trunksVp: (map['trunksVp'] as int?) ?? 0,
        canopyVp: (map['canopyVp'] as int?) ?? 0,
        terrainVp: (map['terrainVp'] as int?) ?? 0,
        personalEcoVp: (map['personalEcoVp'] as int?) ?? 0,
        sharedEcoVp: (map['sharedEcoVp'] as int?) ?? 0,
        compostCards: (map['compostCards'] as int?) ?? 0,
        eventsVp: (map['eventsVp'] as int?) ?? 0,
        faunaBoardVp: (map['faunaBoardVp'] as int?) ?? 0,
      );
}
