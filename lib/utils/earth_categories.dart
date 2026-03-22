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
/// Order follows the official scoring steps from the Earth rulebook.
/// The [key] values must match the field names used in PlayerScore and
/// score_calculator.dart so that the UI and logic stay in sync.
const List<EarthCategory> kEarthCategories = [
  // ── Step 1: Card base VP ─────────────────────────────────────────────────
  // Island + Climate + all tableau cards (NOT Event cards, hand cards, or
  // cards in Compost).
  EarthCategory(
    key: 'islandCardVp',
    label: 'Island Card VP',
    tooltip: 'Base VP (♦) printed on your Island card.',
    icon: Icons.landscape,
    iconColor: Color(0xFF6D4C41), // brown
  ),
  EarthCategory(
    key: 'climateCardVp',
    label: 'Climate Card VP',
    tooltip: 'Base VP (♦) printed on your Climate card.',
    icon: Icons.wb_cloudy,
    iconColor: Color(0xFF42A5F5), // blue
  ),
  EarthCategory(
    key: 'tableauCardsVp',
    label: 'Tableau Cards VP',
    tooltip: 'Total base VP (♦) from all flora & fauna cards in your 4×4 tableau. Do NOT include Event cards, cards in your hand, or cards in your Compost.',
    icon: Icons.grid_view,
    iconColor: Color(0xFF66BB6A), // green
  ),

  // ── Step 2: Event space VP ───────────────────────────────────────────────
  EarthCategory(
    key: 'eventsVp',
    label: 'Events VP',
    tooltip: 'Base VP from cards in your Event space. Can be negative.',
    icon: Icons.bolt,
    iconColor: Color(0xFFEF5350), // red
  ),

  // ── Steps 3–6: Tokens & Growth ───────────────────────────────────────────
  EarthCategory(
    key: 'compostCards',
    label: 'Compost Cards',
    subtitle: '×1 VP per card',
    tooltip: 'Step 3: Count cards in your Compost pile. Each = 1 VP.',
    icon: Icons.compost,
    iconColor: Color(0xFF4E342E), // dark-brown
    multiplier: 1,
  ),
  EarthCategory(
    key: 'sproutsRemaining',
    label: 'Sprouts',
    subtitle: '×1 VP per sprout',
    tooltip: 'Step 4: Count Sprout tokens in your tableau. Each = 1 VP.',
    icon: Icons.eco,
    iconColor: Color(0xFF43A047), // mid-green
    multiplier: 1,
  ),
  EarthCategory(
    key: 'growthVp',
    label: 'Trunks / Canopy VP',
    tooltip: 'Step 5: Score 1VP per Trunk in your tableau. If the Canopy has been placed on a stack, score the Canopy completion VP instead of 1VP/Trunk for that stack.',
    icon: Icons.park,
    iconColor: Color(0xFF2E7D32), // dark-green
  ),
  EarthCategory(
    key: 'terrainVp',
    label: 'Terrain VP',
    tooltip: 'Step 6: VP from Terrain cards in your tableau that have end-game scoring bonuses. Terrains with only in-game effects score 0 VP here.',
    icon: Icons.terrain,
    iconColor: Color(0xFF8D6E63), // brown-light
  ),

  // ── Step 7: Ecosystem Objectives ─────────────────────────────────────────
  EarthCategory(
    key: 'personalEcosystemVp',
    label: 'Personal Ecosystem VP',
    tooltip: 'Step 7: VP from your fulfilled personal Ecosystem objective card.',
    icon: Icons.person_pin,
    iconColor: Color(0xFF7B1FA2), // purple
  ),
  EarthCategory(
    key: 'sharedEcosystemVp',
    label: 'Shared Ecosystem VP',
    tooltip: 'Step 7: VP from the two shared Ecosystem objectives you fulfilled.',
    icon: Icons.groups,
    iconColor: Color(0xFF0288D1), // light-blue
  ),
  EarthCategory(
    key: 'firstTableauComplete',
    label: 'First 4×4 Tableau Complete',
    subtitle: '+7 VP bonus',
    tooltip: 'Step 7: Check if this player was the first to fill all 16 tableau spaces (triggers end-game). Earns 7 VP.',
    icon: Icons.workspace_premium,
    iconColor: Color(0xFFFFB300), // amber
    isCheckbox: true,
  ),

  // ── Step 8: Fauna Board ───────────────────────────────────────────────────
  EarthCategory(
    key: 'faunaBoardVp',
    label: 'Fauna Board VP',
    tooltip: 'Step 8: VP from Leaf tokens placed on the Fauna board.',
    icon: Icons.cruelty_free,
    iconColor: Color(0xFF00897B), // teal
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
