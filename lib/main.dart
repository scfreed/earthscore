import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'utils/hive_adapters.dart';
import 'providers/hive_providers.dart';
import 'app.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive ──────────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  registerHiveAdapters();

  final playersBox  = await Hive.openBox('players');
  final gamesBox    = await Hive.openBox('games');
  final settingsBox = await Hive.openBox('settings');

  // ── Bootstrap ─────────────────────────────────────────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        playersBoxProvider.overrideWithValue(playersBox),
        gamesBoxProvider.overrideWithValue(gamesBox),
        settingsBoxProvider.overrideWithValue(settingsBox),
      ],
      child: const EarthScoreApp(),
    ),
  );
}
