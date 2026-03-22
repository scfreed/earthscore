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

/// All scoring categories in the order they appear on the scoring screen.
/// The [key] values must match the field names used in PlayerScore and
/// score_calculator.dart so that the UI and logic stay in sync.
const List<EarthCategory> kEarthCategories = [
  // ── Card VP ──────────────────────────────────────────────────────────────
  EarthCategory(
    key: 'islandCardVp',
    label: 'Island Card VP',
    tooltip: 'Points printed on your Island card.',
    icon: Icons.landscape,
    iconColor: Color(0xFF6D4C41), // brown
  ),
  EarthCategory(
    key: 'climateCardVp',
    label: 'Climate Card VP',
    tooltip: 'Points printed on your Climate card.',
    icon: Icons.wb_cloudy,
    iconColor: Color(0xFF42A5F5), // blue
  ),
  EarthCategory(
    key: 'tableauCardsVp',
    label: 'Tableau Cards VP',
    tooltip: 'Total VP from all flora & fauna cards in your tableau.',
    icon: Icons.grid_view,
    iconColor: Color(0xFF66BB6A), // green
  ),
  EarthCategory(
    key: 'eventsVp',
    label: 'Events VP',
    tooltip: 'Points earned from Event cards scored at end of game.',
    icon: Icons.event,
    iconColor: Color(0xFFEF5350), // red
  ),

  // ── Board tokens ─────────────────────────────────────────────────────────
  EarthCategory(
    key: 'terrainVp',
    label: 'Terrain VP',
    tooltip: 'Points from terrain tokens placed on your board.',
    icon: Icons.terrain,
    iconColor: Color(0xFF8D6E63), // brown-light
  ),
  EarthCategory(
    key: 'compostCards',
    label: 'Compost Cards',
    subtitle: '×1 VP per card',
    tooltip: 'Number of cards in your compost pile. Each card = 1 VP.',
    icon: Icons.compost,
    iconColor: Color(0xFF4E342E), // dark-brown
    multiplier: 1,
  ),
  EarthCategory(
    key: 'sproutsRemaining',
    label: 'Sprouts Remaining',
    subtitle: '×1 VP per sprout',
    tooltip: 'Number of sprout tokens left on your board. Each = 1 VP.',
    icon: Icons.eco,
    iconColor: Color(0xFF43A047), // mid-green
    multiplier: 1,
  ),
  EarthCategory(
    key: 'growthVp',
    label: 'Growth / Trunks / Canopies',
    tooltip: 'Combined VP from growth cubes, trunk tokens, and canopy tokens.',
    icon: Icons.park,
    iconColor: Color(0xFF2E7D32), // dark-green
  ),

  // ── Objectives ───────────────────────────────────────────────────────────
  EarthCategory(
    key: 'personalEcosystemVp',
    label: 'Personal Ecosystem VP',
    tooltip: 'Points from your personal ecosystem objective card.',
    icon: Icons.person_pin,
    iconColor: Color(0xFF7B1FA2), // purple
  ),
  EarthCategory(
    key: 'sharedEcosystemVp',
    label: 'Shared Ecosystem VP',
    tooltip: 'Points from shared ecosystem objectives (up to 2) plus any bonuses.',
    icon: Icons.groups,
    iconColor: Color(0xFF0288D1), // light-blue
  ),

  // ── Fauna board ──────────────────────────────────────────────────────────
  EarthCategory(
    key: 'faunaBoardVp',
    label: 'Fauna Board VP',
    tooltip: 'Leaf tokens earned by completing fauna board objectives.',
    icon: Icons.cruelty_free,
    iconColor: Color(0xFF00897B), // teal
  ),

  // ── First-complete bonus ──────────────────────────────────────────────────
  EarthCategory(
    key: 'firstTableauComplete',
    label: 'First 4×4 Tableau Complete',
    subtitle: '+7 VP bonus',
    tooltip: 'Check if this player was the first to fill all 16 tableau spaces.',
    icon: Icons.workspace_premium,
    iconColor: Color(0xFFFFB300), // amber
    isCheckbox: true,
  ),

  // ── Freeform ─────────────────────────────────────────────────────────────
  EarthCategory(
    key: 'otherVp',
    label: 'Other / Bonus VP',
    tooltip: 'Any additional VP from house rules, promo cards, or expansions.',
    icon: Icons.add_circle_outline,
    iconColor: Color(0xFF546E7A), // blue-grey
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
