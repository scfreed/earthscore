/// One player's complete score for a single game.
/// Fields match the 10 columns on the Earth scoresheet, in scoresheet order.
/// The [total] getter sums every column.
class PlayerScore {
  final String playerId;

  // ── Col 1: Base card VP ───────────────────────────────────────────────────
  int cardsVp;          // Island + Climate + all Tableau cards (not Events/hand/Compost)

  // ── Col 2–3: Growth tokens ────────────────────────────────────────────────
  int sproutsVp;        // Sprout tokens in tableau          (×1 VP each)
  int growthVp;         // Trunks (×1 VP each) + any Canopy completion VP combined

  // ── Col 5: Terrain ────────────────────────────────────────────────────────
  int terrainVp;        // End-game bonus from Terrain cards

  // ── Col 5–7: Ecosystem objectives ─────────────────────────────────────────
  int personalEcoVp;    // Personal Ecosystem objective
  int sharedEco1Vp;     // First shared Ecosystem objective
  int sharedEco2Vp;     // Second shared Ecosystem objective

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
    this.growthVp = 0,
    this.terrainVp = 0,
    this.personalEcoVp = 0,
    this.sharedEco1Vp = 0,
    this.sharedEco2Vp = 0,
    this.compostCards = 0,
    this.eventsVp = 0,
    this.faunaBoardVp = 0,
  });

  int get total =>
      cardsVp +
      sproutsVp +
      growthVp +
      terrainVp +
      personalEcoVp +
      sharedEco1Vp +
      sharedEco2Vp +
      compostCards +
      eventsVp +
      faunaBoardVp;

  PlayerScore copyWith({
    String? playerId,
    int? cardsVp,
    int? sproutsVp,
    int? growthVp,
    int? terrainVp,
    int? personalEcoVp,
    int? sharedEco1Vp,
    int? sharedEco2Vp,
    int? compostCards,
    int? eventsVp,
    int? faunaBoardVp,
  }) {
    return PlayerScore(
      playerId: playerId ?? this.playerId,
      cardsVp: cardsVp ?? this.cardsVp,
      sproutsVp: sproutsVp ?? this.sproutsVp,
      growthVp: growthVp ?? this.growthVp,
      terrainVp: terrainVp ?? this.terrainVp,
      personalEcoVp: personalEcoVp ?? this.personalEcoVp,
      sharedEco1Vp: sharedEco1Vp ?? this.sharedEco1Vp,
      sharedEco2Vp: sharedEco2Vp ?? this.sharedEco2Vp,
      compostCards: compostCards ?? this.compostCards,
      eventsVp: eventsVp ?? this.eventsVp,
      faunaBoardVp: faunaBoardVp ?? this.faunaBoardVp,
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'cardsVp': cardsVp,
        'sproutsVp': sproutsVp,
        'growthVp': growthVp,
        'terrainVp': terrainVp,
        'personalEcoVp': personalEcoVp,
        'sharedEco1Vp': sharedEco1Vp,
        'sharedEco2Vp': sharedEco2Vp,
        'compostCards': compostCards,
        'eventsVp': eventsVp,
        'faunaBoardVp': faunaBoardVp,
      };

  factory PlayerScore.fromMap(Map<dynamic, dynamic> map) => PlayerScore(
        playerId: map['playerId'] as String,
        cardsVp: (map['cardsVp'] as int?) ?? 0,
        sproutsVp: (map['sproutsVp'] as int?) ?? 0,
        growthVp: (map['growthVp'] as int?) ?? 0,
        terrainVp: (map['terrainVp'] as int?) ?? 0,
        personalEcoVp: (map['personalEcoVp'] as int?) ?? 0,
        sharedEco1Vp: (map['sharedEco1Vp'] as int?) ?? 0,
        sharedEco2Vp: (map['sharedEco2Vp'] as int?) ?? 0,
        compostCards: (map['compostCards'] as int?) ?? 0,
        eventsVp: (map['eventsVp'] as int?) ?? 0,
        faunaBoardVp: (map['faunaBoardVp'] as int?) ?? 0,
      );
}
