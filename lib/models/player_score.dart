/// One player's complete score for a single game.
/// All fields default to 0 / false. The [total] getter computes the
/// final score, applying multipliers where the rules require them.
class PlayerScore {
  final String playerId;

  // ── Card VP ──────────────────────────────────────────────────────────────
  int islandCardVp;       // Island card direct VP
  int climateCardVp;      // Climate card direct VP
  int tableauCardsVp;     // Sum of all tableau (flora/fauna) card VP
  int eventsVp;           // Events scored at end of game

  // ── Board tokens ─────────────────────────────────────────────────────────
  int terrainVp;          // Terrain tokens on the board
  int compostCards;       // Cards in compost pile  (×1 VP each)
  int sproutsRemaining;   // Sprout tokens left     (×1 VP each)
  int growthVp;           // Growth / trunks / canopies combined VP

  // ── Objectives ───────────────────────────────────────────────────────────
  int personalEcosystemVp;  // Personal ecosystem objective
  int sharedEcosystemVp;    // Shared ecosystem objectives (up to 2 + bonuses)

  // ── Fauna board ──────────────────────────────────────────────────────────
  int faunaBoardVp;       // Leaf tokens placed on fauna board

  // ── First-complete bonus ──────────────────────────────────────────────────
  bool firstTableauComplete;  // Did this player complete the 4×4 first?
  int firstTableauBonusVp;    // Configurable; default = 7

  // ── Freeform ─────────────────────────────────────────────────────────────
  int otherVp;
  String otherNote;

  PlayerScore({
    required this.playerId,
    this.islandCardVp = 0,
    this.climateCardVp = 0,
    this.tableauCardsVp = 0,
    this.eventsVp = 0,
    this.terrainVp = 0,
    this.compostCards = 0,
    this.sproutsRemaining = 0,
    this.growthVp = 0,
    this.personalEcosystemVp = 0,
    this.sharedEcosystemVp = 0,
    this.faunaBoardVp = 0,
    this.firstTableauComplete = false,
    this.firstTableauBonusVp = 7,
    this.otherVp = 0,
    this.otherNote = '',
  });

  int get total =>
      islandCardVp +
      climateCardVp +
      tableauCardsVp +
      eventsVp +
      terrainVp +
      compostCards +       // ×1
      sproutsRemaining +   // ×1
      growthVp +
      personalEcosystemVp +
      sharedEcosystemVp +
      faunaBoardVp +
      (firstTableauComplete ? firstTableauBonusVp : 0) +
      otherVp;

  PlayerScore copyWith({
    String? playerId,
    int? islandCardVp,
    int? climateCardVp,
    int? tableauCardsVp,
    int? eventsVp,
    int? terrainVp,
    int? compostCards,
    int? sproutsRemaining,
    int? growthVp,
    int? personalEcosystemVp,
    int? sharedEcosystemVp,
    int? faunaBoardVp,
    bool? firstTableauComplete,
    int? firstTableauBonusVp,
    int? otherVp,
    String? otherNote,
  }) {
    return PlayerScore(
      playerId: playerId ?? this.playerId,
      islandCardVp: islandCardVp ?? this.islandCardVp,
      climateCardVp: climateCardVp ?? this.climateCardVp,
      tableauCardsVp: tableauCardsVp ?? this.tableauCardsVp,
      eventsVp: eventsVp ?? this.eventsVp,
      terrainVp: terrainVp ?? this.terrainVp,
      compostCards: compostCards ?? this.compostCards,
      sproutsRemaining: sproutsRemaining ?? this.sproutsRemaining,
      growthVp: growthVp ?? this.growthVp,
      personalEcosystemVp: personalEcosystemVp ?? this.personalEcosystemVp,
      sharedEcosystemVp: sharedEcosystemVp ?? this.sharedEcosystemVp,
      faunaBoardVp: faunaBoardVp ?? this.faunaBoardVp,
      firstTableauComplete: firstTableauComplete ?? this.firstTableauComplete,
      firstTableauBonusVp: firstTableauBonusVp ?? this.firstTableauBonusVp,
      otherVp: otherVp ?? this.otherVp,
      otherNote: otherNote ?? this.otherNote,
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'islandCardVp': islandCardVp,
        'climateCardVp': climateCardVp,
        'tableauCardsVp': tableauCardsVp,
        'eventsVp': eventsVp,
        'terrainVp': terrainVp,
        'compostCards': compostCards,
        'sproutsRemaining': sproutsRemaining,
        'growthVp': growthVp,
        'personalEcosystemVp': personalEcosystemVp,
        'sharedEcosystemVp': sharedEcosystemVp,
        'faunaBoardVp': faunaBoardVp,
        'firstTableauComplete': firstTableauComplete,
        'firstTableauBonusVp': firstTableauBonusVp,
        'otherVp': otherVp,
        'otherNote': otherNote,
      };

  factory PlayerScore.fromMap(Map<dynamic, dynamic> map) => PlayerScore(
        playerId: map['playerId'] as String,
        islandCardVp: (map['islandCardVp'] as int?) ?? 0,
        climateCardVp: (map['climateCardVp'] as int?) ?? 0,
        tableauCardsVp: (map['tableauCardsVp'] as int?) ?? 0,
        eventsVp: (map['eventsVp'] as int?) ?? 0,
        terrainVp: (map['terrainVp'] as int?) ?? 0,
        compostCards: (map['compostCards'] as int?) ?? 0,
        sproutsRemaining: (map['sproutsRemaining'] as int?) ?? 0,
        growthVp: (map['growthVp'] as int?) ?? 0,
        personalEcosystemVp: (map['personalEcosystemVp'] as int?) ?? 0,
        sharedEcosystemVp: (map['sharedEcosystemVp'] as int?) ?? 0,
        faunaBoardVp: (map['faunaBoardVp'] as int?) ?? 0,
        firstTableauComplete: (map['firstTableauComplete'] as bool?) ?? false,
        firstTableauBonusVp: (map['firstTableauBonusVp'] as int?) ?? 7,
        otherVp: (map['otherVp'] as int?) ?? 0,
        otherNote: (map['otherNote'] as String?) ?? '',
      );
}
