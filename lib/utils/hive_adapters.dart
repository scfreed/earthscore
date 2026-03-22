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
      cardsVp: (f[1] as int?) ?? 0,
      sproutsVp: (f[2] as int?) ?? 0,
      growthVp: (f[3] as int?) ?? 0,
      terrainVp: (f[4] as int?) ?? 0,
      personalEcoVp: (f[5] as int?) ?? 0,
      sharedEco1Vp: (f[6] as int?) ?? 0,
      sharedEco2Vp: (f[7] as int?) ?? 0,
      compostCards: (f[8] as int?) ?? 0,
      eventsVp: (f[9] as int?) ?? 0,
      faunaBoardVp: (f[10] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerScore obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(obj.playerId)
      ..writeByte(1)..write(obj.cardsVp)
      ..writeByte(2)..write(obj.sproutsVp)
      ..writeByte(3)..write(obj.growthVp)
      ..writeByte(4)..write(obj.terrainVp)
      ..writeByte(5)..write(obj.personalEcoVp)
      ..writeByte(6)..write(obj.sharedEco1Vp)
      ..writeByte(7)..write(obj.sharedEco2Vp)
      ..writeByte(8)..write(obj.compostCards)
      ..writeByte(9)..write(obj.eventsVp)
      ..writeByte(10)..write(obj.faunaBoardVp);
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
