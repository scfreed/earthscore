import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// These providers are overridden in main.dart after the boxes are opened,
// so the throw here is never reached at runtime.

final playersBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('playersBox not initialised'),
);

final gamesBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('gamesBox not initialised'),
);

final settingsBoxProvider = Provider<Box>(
  (ref) => throw UnimplementedError('settingsBox not initialised'),
);
