import 'package:flutter/material.dart';

class Player {
  final String id;
  final String name;
  final String colorHex; // e.g. "FF4CAF50"
  final int createdAtMs;

  const Player({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAtMs,
  });

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);

  Color get color => Color(int.parse(colorHex, radix: 16));

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Player copyWith({String? id, String? name, String? colorHex, int? createdAtMs}) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'createdAtMs': createdAtMs,
      };

  factory Player.fromMap(Map<dynamic, dynamic> map) => Player(
        id: map['id'] as String,
        name: map['name'] as String,
        colorHex: map['colorHex'] as String,
        createdAtMs: map['createdAtMs'] as int,
      );
}

/// Predefined palette for player colour selection.
const List<String> kPlayerColors = [
  'FF4CAF50', // green
  'FF2196F3', // blue
  'FFF44336', // red
  'FFFF9800', // orange
  'FF9C27B0', // purple
  'FFFF5722', // deep-orange
  'FF00BCD4', // cyan
  'FFE91E63', // pink
  'FF795548', // brown
  'FF607D8B', // blue-grey
];
