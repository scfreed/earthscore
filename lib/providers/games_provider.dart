import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/game.dart';
import 'hive_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

class GamesNotifier extends StateNotifier<List<Game>> {
  GamesNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'games';

  static List<Game> _load(Box box) {
    final raw = box.get(_key);
    if (raw == null) return [];
    final list = (raw as List)
        .map((e) {
          try {
            return Game.fromMap(e as Map);
          } catch (_) {
            return null;
          }
        })
        .whereType<Game>()
        .toList();
    // Always sorted newest-first.
    list.sort((a, b) => b.dateMs.compareTo(a.dateMs));
    return list;
  }

  void _save() {
    final sorted = List<Game>.from(state)
      ..sort((a, b) => b.dateMs.compareTo(a.dateMs));
    _box.put(_key, sorted.map((g) => g.toMap()).toList());
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void saveGame(Game game) {
    final existing = state.indexWhere((g) => g.id == game.id);
    if (existing >= 0) {
      final next = List<Game>.from(state);
      next[existing] = game;
      state = next;
    } else {
      state = [game, ...state];
    }
    _save();
  }

  void deleteGame(String id) {
    state = state.where((g) => g.id != id).toList();
    _save();
  }

  Game? byId(String id) {
    try {
      return state.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

final gamesProvider =
    StateNotifierProvider<GamesNotifier, List<Game>>((ref) {
  final box = ref.watch(gamesBoxProvider);
  return GamesNotifier(box);
});

/// Last N games (default 5) sorted newest-first — used on the home dashboard.
final recentGamesProvider = Provider.family<List<Game>, int>((ref, n) {
  final games = ref.watch(gamesProvider);
  return games.take(n).toList();
});
