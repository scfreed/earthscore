import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/game.dart';
import '../models/player.dart';
import '../models/player_score.dart';
import 'earth_categories.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared value extractor
// ─────────────────────────────────────────────────────────────────────────────

int _val(PlayerScore s, String key) {
  switch (key) {
    case 'cardsVp':       return s.cardsVp;
    case 'sproutsVp':     return s.sproutsVp;
    case 'trunksVp':      return s.trunksVp;
    case 'canopyVp':      return s.canopyVp;
    case 'terrainVp':     return s.terrainVp;
    case 'personalEcoVp': return s.personalEcoVp;
    case 'sharedEcoVp':   return s.sharedEcoVp;
    case 'compostCards':  return s.compostCards;
    case 'eventsVp':      return s.eventsVp;
    case 'faunaBoardVp':  return s.faunaBoardVp;
    default:              return 0;
  }
}

String _playerName(List<Player?> players, String id) =>
    players.where((p) => p?.id == id).firstOrNull?.name ?? 'Player';

// ─────────────────────────────────────────────────────────────────────────────
// Image export
// ─────────────────────────────────────────────────────────────────────────────

Future<void> exportAsImage({
  required BuildContext context,
  required Game game,
  required List<Player?> players,
}) async {
  final ctrl = ScreenshotController();

  final Uint8List bytes = await ctrl.captureFromLongWidget(
    InheritedTheme.captureAll(
      context,
      Material(
        color: Colors.white,
        child: ScoreCardWidget(game: game, players: players),
      ),
    ),
    pixelRatio: 2.5,
    context: context,
    constraints: const BoxConstraints(maxWidth: 600),
  );

  final dir  = await getTemporaryDirectory();
  final slug = (game.name.isEmpty ? 'earth_game' : game.name)
      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
      .toLowerCase();
  final file = File('${dir.path}/${slug}_${game.id.substring(0, 8)}.png');
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png')],
    subject: game.name.isEmpty ? 'EarthScore Game' : game.name,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV export
// ─────────────────────────────────────────────────────────────────────────────

Future<void> exportAsCsv({
  required Game game,
  required List<Player?> players,
}) async {
  final rows = <List<dynamic>>[];

  final title = game.name.isEmpty ? 'Earth Game' : game.name;
  rows.add(['EarthScore — $title']);
  rows.add(['Date', DateFormat('yyyy-MM-dd').format(game.date)]);
  if (game.notes.isNotEmpty) rows.add(['Notes', game.notes]);
  rows.add([]);

  // Column headers: Category + player names
  rows.add([
    'Category',
    ...game.playerIds.map((id) => _playerName(players, id)),
  ]);

  // One row per scoring category
  for (final cat in kEarthCategories) {
    rows.add([
      cat.label,
      ...game.playerIds.map((id) {
        final s = game.scoreFor(id);
        if (s == null) return 0;
        return _val(s, cat.key);
      }),
    ]);
  }

  rows.add([]);

  // Total
  rows.add([
    'TOTAL',
    ...game.playerIds.map((id) => game.scoreFor(id)?.total ?? 0),
  ]);

  // Winner(s)
  final winnerNames = game.winnerIds
      .map((id) => _playerName(players, id))
      .join(', ');
  rows.add(['Winner', winnerNames]);

  final csv = const ListToCsvConverter().convert(rows);

  final dir  = await getTemporaryDirectory();
  final slug = (game.name.isEmpty ? 'earth_game' : game.name)
      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
      .toLowerCase();
  final file = File('${dir.path}/${slug}_${game.id.substring(0, 8)}.csv');
  await file.writeAsString(csv);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: '$title — EarthScore data',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Scorecard widget  (rendered to image; uses hardcoded colours, no Theme)
// ─────────────────────────────────────────────────────────────────────────────

const _kGreen      = Color(0xFF4E8B3F);
const _kGreenDark  = Color(0xFF2E5A28);
const _kGold       = Color(0xFFFFB300);
const _kGoldLight  = Color(0xFFFFF8E1);
const _kBgAlt      = Color(0xFFF4F8F1);
const _kBorder     = Color(0xFFDEE8DA);
const _kText       = Color(0xFF1C2B1A);
const _kTextLight  = Color(0xFF6B7F68);
const _kColW       = 150.0;
const _kPlayerW    = 72.0;
const _kRowH       = 32.0;
const _kHeaderH    = 52.0;

// Short labels for compact table
const _shortLabels = {
  'cardsVp':       'Cards VP',
  'sproutsVp':     'Sprouts (×1)',
  'trunksVp':      'Trunks (×1)',
  'canopyVp':      'Canopy VP',
  'terrainVp':     'Terrain VP',
  'personalEcoVp': 'Personal Eco',
  'sharedEcoVp':   'Shared Eco',
  'compostCards':  'Compost (×1)',
  'eventsVp':      'Events VP',
  'faunaBoardVp':  'Fauna Board',
};

const _groupLabels = {
  0: 'Card VP',
  1: 'Growth',
  4: 'Terrain',
  5: 'Ecosystem',
  7: 'Compost & Events',
  9: 'Fauna Board',
};

class ScoreCardWidget extends StatelessWidget {
  const ScoreCardWidget({super.key, required this.game, required this.players});
  final Game game;
  final List<Player?> players;

  @override
  Widget build(BuildContext context) {
    final winners   = game.winnerIds;
    final topScore  = game.rankedScores.isEmpty ? 0 : game.rankedScores.first.total;
    final winnerStr = winners
        .map((id) => _playerName(players, id))
        .join(' & ');
    final dateStr   = DateFormat('MMMM d, yyyy').format(game.date);
    final n         = game.playerIds.length;
    final tableW    = _kColW + _kPlayerW * n;

    return SizedBox(
      width: tableW + 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Green header ────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreen, _kGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.eco, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'EarthScore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  game.name.isEmpty ? 'Earth Game' : game.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── Winner banner ────────────────────────────────────────────────
          Container(
            color: _kGold,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    winners.length > 1
                        ? 'Tied: $winnerStr — $topScore VP'
                        : 'Winner: $winnerStr — $topScore VP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Comparison table ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Player header row
                _TableRow(
                  isHeader: true,
                  label: 'Category',
                  values: game.playerIds
                      .map((id) => _playerName(players, id))
                      .toList(),
                  winners: winners,
                  playerIds: game.playerIds,
                ),
                const _HDivider(),

                // Category rows
                for (var i = 0; i < kEarthCategories.length; i++) ...[
                  if (_groupLabels.containsKey(i) && i != 0)
                    _GroupHeaderRow(
                        label: _groupLabels[i]!,
                        width: tableW + 32),
                  _TableRow(
                    isHeader: false,
                    isAlt: i.isEven,
                    label: _shortLabels[kEarthCategories[i].key] ??
                        kEarthCategories[i].label,
                    values: game.playerIds.map((id) {
                      final s = game.scoreFor(id);
                      if (s == null) return '—';
                      final v = _val(s, kEarthCategories[i].key);
                      return v == 0 ? '—' : '$v';
                    }).toList(),
                    winners: winners,
                    playerIds: game.playerIds,
                  ),
                ],

                const _HDivider(thick: true),

                // Total row
                _TableRow(
                  isHeader: false,
                  isTotalRow: true,
                  label: 'TOTAL',
                  values: game.playerIds
                      .map((id) => '${game.scoreFor(id)?.total ?? 0}')
                      .toList(),
                  winners: winners,
                  playerIds: game.playerIds,
                ),
              ],
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          Container(
            color: _kBgAlt,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.eco, color: _kGreen, size: 13),
                const SizedBox(width: 4),
                const Text(
                  'Scored with EarthScore',
                  style: TextStyle(
                    color: _kTextLight,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('yyyy-MM-dd').format(game.date),
                  style: const TextStyle(color: _kTextLight, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.label,
    required this.values,
    required this.winners,
    required this.playerIds,
    this.isHeader   = false,
    this.isTotalRow = false,
    this.isAlt      = false,
  });

  final String label;
  final List<String> values;
  final List<String> winners;
  final List<String> playerIds;
  final bool isHeader;
  final bool isTotalRow;
  final bool isAlt;

  @override
  Widget build(BuildContext context) {
    final rowColor = isHeader
        ? _kGreen.withValues(alpha: 0.08)
        : isTotalRow
            ? _kBgAlt
            : isAlt
                ? _kBgAlt
                : Colors.white;

    return Container(
      height: isHeader ? _kHeaderH : _kRowH,
      color: rowColor,
      child: Row(
        children: [
          // Label cell
          SizedBox(
            width: _kColW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isHeader ? 11 : 11,
                  fontWeight: isTotalRow || isHeader
                      ? FontWeight.w800
                      : FontWeight.normal,
                  color: isTotalRow ? _kGreen : _kText,
                  letterSpacing: isTotalRow ? 0.5 : 0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Score cells
          for (var i = 0; i < playerIds.length; i++)
            Container(
              width: _kPlayerW,
              decoration: BoxDecoration(
                color: winners.contains(playerIds[i])
                    ? _kGoldLight
                    : null,
                border: const Border(
                  left: BorderSide(
                      color: _kBorder, width: 0.5),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                values[i],
                style: TextStyle(
                  fontSize: isHeader ? 12 : 11,
                  fontWeight: isHeader || isTotalRow
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: values[i] == '—'
                      ? _kTextLight
                      : isTotalRow && winners.contains(playerIds[i])
                          ? _kGold
                          : isTotalRow
                              ? _kText
                              : _kText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHeaderRow extends StatelessWidget {
  const _GroupHeaderRow({required this.label, required this.width});
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 20,
      color: _kGreen.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: _kGreen,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _HDivider extends StatelessWidget {
  const _HDivider({this.thick = false});
  final bool thick;

  @override
  Widget build(BuildContext context) => Container(
        height: thick ? 1.5 : 0.5,
        color: thick ? _kGreen.withValues(alpha: 0.4) : _kBorder,
      );
}
