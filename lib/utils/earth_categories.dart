import 'package:flutter/material.dart';

/// Describes one row in the scoring form.
class EarthCategory {
  final String key;          // matches PlayerScore field name
  final String label;        // display label
  final String tooltip;      // helper text shown in UI
  final IconData icon;       // Material icon
  final Color iconColor;     // tint for the icon
  final bool isCheckbox;     // true → yes/no toggle instead of number input
  final int multiplier;      // VP per unit (usually 1; shown in tooltip)
  final String? subtitle;    // optional second line of text

  const EarthCategory({
    required this.key,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    this.isCheckbox = false,
    this.multiplier = 1,
    this.subtitle,
  });
}

/// Scoring categories in scoresheet column order (left → right after the M column).
/// Keys match PlayerScore field names exactly.
const List<EarthCategory> kEarthCategories = [
  // ── Col 1: Base card VP ───────────────────────────────────────────────────
  EarthCategory(
    key: 'cardsVp',
    label: 'Cards VP',
    tooltip: 'Total base VP (♦) from your Island card + Climate card + all cards in your 4×4 tableau. Do NOT count Event cards, cards in your hand, or cards in your Compost.',
    icon: Icons.style,
    iconColor: Color(0xFF5D4037), // brown
  ),

  // ── Col 2–3: Growth tokens ────────────────────────────────────────────────
  EarthCategory(
    key: 'sproutsVp',
    label: 'Sprouts',
    subtitle: '×1 VP per sprout',
    tooltip: 'Count Sprout tokens in your tableau. Each = 1 VP.',
    icon: Icons.eco,
    iconColor: Color(0xFF43A047), // green
    multiplier: 1,
  ),
  EarthCategory(
    key: 'growthVp',
    label: 'Trunks / Canopy VP',
    tooltip: 'Score 1VP per Trunk in your tableau. If the Canopy has been placed on a stack, score the Canopy completion VP for that stack instead of 1VP/Trunk. Enter the combined total here.',
    icon: Icons.forest,
    iconColor: Color(0xFF2E7D32), // dark-green
  ),

  // ── Col 5: Terrain ────────────────────────────────────────────────────────
  EarthCategory(
    key: 'terrainVp',
    label: 'Terrain VP',
    tooltip: 'VP from Terrain cards in your tableau that have end-game scoring bonuses. Terrains with only in-game effects score 0 VP here.',
    icon: Icons.terrain,
    iconColor: Color(0xFF8D6E63), // brown-light
  ),

  // ── Col 5–7: Ecosystem objectives ─────────────────────────────────────────
  EarthCategory(
    key: 'personalEcoVp',
    label: 'Personal Ecosystem',
    tooltip: 'VP from your fulfilled personal Ecosystem objective card. Include the +7 VP bonus here if you were the first to complete your 4×4 tableau.',
    icon: Icons.person_pin,
    iconColor: Color(0xFF7B1FA2), // purple
  ),
  EarthCategory(
    key: 'sharedEco1Vp',
    label: 'Shared Ecosystem 1',
    tooltip: 'VP from the first shared Ecosystem objective.',
    icon: Icons.groups,
    iconColor: Color(0xFF0288D1), // blue
  ),
  EarthCategory(
    key: 'sharedEco2Vp',
    label: 'Shared Ecosystem 2',
    tooltip: 'VP from the second shared Ecosystem objective.',
    icon: Icons.groups_outlined,
    iconColor: Color(0xFF0277BD), // darker blue
  ),

  // ── Col 8: Compost ────────────────────────────────────────────────────────
  EarthCategory(
    key: 'compostCards',
    label: 'Compost',
    subtitle: '×1 VP per card',
    tooltip: 'Count cards in your Compost pile. Each = 1 VP.',
    icon: Icons.recycling,
    iconColor: Color(0xFF4E342E), // dark-brown
    multiplier: 1,
  ),

  // ── Col 9: Events ─────────────────────────────────────────────────────────
  EarthCategory(
    key: 'eventsVp',
    label: 'Events VP',
    tooltip: 'Base VP (♦) from cards in your Event space. Can be negative.',
    icon: Icons.bolt,
    iconColor: Color(0xFFEF5350), // red
  ),

  // ── Col 10: Fauna Board ───────────────────────────────────────────────────
  EarthCategory(
    key: 'faunaBoardVp',
    label: 'Fauna Board VP',
    tooltip: 'VP from Leaf tokens placed on the Fauna board.',
    icon: Icons.cruelty_free,
    iconColor: Color(0xFF00897B), // teal
  ),
];

/// Lookup a category by its key.
EarthCategory? categoryByKey(String key) {
  try {
    return kEarthCategories.firstWhere((c) => c.key == key);
  } catch (_) {
    return null;
  }
}
