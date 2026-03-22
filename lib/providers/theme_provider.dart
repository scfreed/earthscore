import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'hive_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'themeMode';

  static ThemeMode _load(Box box) {
    final stored = box.get(_key, defaultValue: 'system') as String;
    return _fromString(stored);
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':  return ThemeMode.light;
      case 'dark':   return ThemeMode.dark;
      default:       return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:  return 'light';
      case ThemeMode.dark:   return 'dark';
      case ThemeMode.system: return 'system';
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _box.put(_key, _toString(mode));
  }

  void toggle() {
    // system → light → dark → light …
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return ThemeNotifier(box);
});
