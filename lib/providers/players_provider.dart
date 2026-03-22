import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/player.dart';
import 'hive_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

class PlayersNotifier extends StateNotifier<List<Player>> {
  PlayersNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'players';
  static const _uuid = Uuid();

  static List<Player> _load(Box box) {
    final raw = box.get(_key);
    if (raw == null) return [];
    return (raw as List).map((e) => Player.fromMap(e as Map)).toList();
  }

  void _save() {
    _box.put(_key, state.map((p) => p.toMap()).toList());
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void addPlayer({required String name, required String colorHex}) {
    final player = Player(
      id: _uuid.v4(),
      name: name.trim(),
      colorHex: colorHex,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    state = [...state, player];
    _save();
  }

  void updatePlayer(Player updated) {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
    _save();
  }

  void deletePlayer(String id) {
    state = state.where((p) => p.id != id).toList();
    _save();
  }

  /// Returns the Player for [id], or null if not found.
  Player? byId(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

final playersProvider =
    StateNotifierProvider<PlayersNotifier, List<Player>>((ref) {
  final box = ref.watch(playersBoxProvider);
  return PlayersNotifier(box);
});

/// Convenience: look up a single player by id (returns null if missing).
final playerByIdProvider = Provider.family<Player?, String>((ref, id) {
  return ref.watch(playersProvider.notifier).byId(id);
});
