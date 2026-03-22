import 'package:hive/hive.dart';
import '../models/player.dart';
import '../models/player_score.dart';
import '../models/game.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Type IDs
//   0 → Player
//   1 → PlayerScore
//   2 → Game
// ─────────────────────────────────────────────────────────────────────────────

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 0;

  @override
  Player read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Player(
      id: fields[0] as String,
      name: fields[1] as String,
      colorHex: fields[2] as String,
      createdAtMs: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorHex)
      ..writeByte(3)
      ..write(obj.createdAtMs);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class PlayerScoreAdapter extends TypeAdapter<PlayerScore> {
  @override
  final int typeId = 1;

  @override
  PlayerScore read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return PlayerScore(
      playerId: f[0] as String,
      islandCardVp: (f[1] as int?) ?? 0,
      climateCardVp: (f[2] as int?) ?? 0,
      tableauCardsVp: (f[3] as int?) ?? 0,
      eventsVp: (f[4] as int?) ?? 0,
      terrainVp: (f[5] as int?) ?? 0,
      compostCards: (f[6] as int?) ?? 0,
      sproutsRemaining: (f[7] as int?) ?? 0,
      growthVp: (f[8] as int?) ?? 0,
      personalEcosystemVp: (f[9] as int?) ?? 0,
      sharedEcosystemVp: (f[10] as int?) ?? 0,
      faunaBoardVp: (f[11] as int?) ?? 0,
      firstTableauComplete: (f[12] as bool?) ?? false,
      firstTableauBonusVp: (f[13] as int?) ?? 7,
      otherVp: (f[14] as int?) ?? 0,
      otherNote: (f[15] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, PlayerScore obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)..write(obj.playerId)
      ..writeByte(1)..write(obj.islandCardVp)
      ..writeByte(2)..write(obj.climateCardVp)
      ..writeByte(3)..write(obj.tableauCardsVp)
      ..writeByte(4)..write(obj.eventsVp)
      ..writeByte(5)..write(obj.terrainVp)
      ..writeByte(6)..write(obj.compostCards)
      ..writeByte(7)..write(obj.sproutsRemaining)
      ..writeByte(8)..write(obj.growthVp)
      ..writeByte(9)..write(obj.personalEcosystemVp)
      ..writeByte(10)..write(obj.sharedEcosystemVp)
      ..writeByte(11)..write(obj.faunaBoardVp)
      ..writeByte(12)..write(obj.firstTableauComplete)
      ..writeByte(13)..write(obj.firstTableauBonusVp)
      ..writeByte(14)..write(obj.otherVp)
      ..writeByte(15)..write(obj.otherNote);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class GameAdapter extends TypeAdapter<Game> {
  @override
  final int typeId = 2;

  @override
  Game read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Game(
      id: f[0] as String,
      name: f[1] as String,
      dateMs: f[2] as int,
      notes: (f[3] as String?) ?? '',
      playerIds: (f[4] as List).cast<String>(),
      scores: (f[5] as List).cast<PlayerScore>(),
    );
  }

  @override
  void write(BinaryWriter writer, Game obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.dateMs)
      ..writeByte(3)..write(obj.notes)
      ..writeByte(4)..write(obj.playerIds)
      ..writeByte(5)..write(obj.scores);
  }
}

/// Call once during app initialisation (before openBox).
void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PlayerAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlayerScoreAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GameAdapter());
}
