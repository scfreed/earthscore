import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/game.dart';
import '../models/player.dart';
import '../models/player_score.dart';
import '../providers/games_provider.dart';
import '../providers/players_provider.dart';
import '../utils/earth_categories.dart';
import '../utils/export_utils.dart';
import '../widgets/player_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

int _valueFor(PlayerScore s, String key) {
  switch (key) {
    case 'islandCardVp':        return s.islandCardVp;
    case 'climateCardVp':       return s.climateCardVp;
    case 'tableauCardsVp':      return s.tableauCardsVp;
    case 'eventsVp':            return s.eventsVp;
    case 'terrainVp':           return s.terrainVp;
    case 'compostCards':        return s.compostCards;
    case 'sproutsRemaining':    return s.sproutsRemaining;
    case 'growthVp':            return s.growthVp;
    case 'personalEcosystemVp': return s.personalEcosystemVp;
    case 'sharedEcosystemVp':   return s.sharedEcosystemVp;
    case 'faunaBoardVp':        return s.faunaBoardVp;
    case 'firstTableauComplete':
      return s.firstTableauComplete ? s.firstTableauBonusVp : 0;
    case 'otherVp':             return s.otherVp;
    default:                    return 0;
  }
}

String _ordinal(int n) {
  if (n == 1) return '1st';
  if (n == 2) return '2nd';
  if (n == 3) return '3rd';
  return '${n}th';
}

int _rankOf(Game game, String playerId) {
  final myScore = game.scoreFor(playerId)?.total ?? 0;
  return game.rankedScores.where((s) => s.total > myScore).length + 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gamesProvider.notifier).byId(gameId);

    if (game == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Game not found.')),
      );
    }

    final players = ref.watch(playersProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Build player list in game order, with fallback for deleted players
    final gamePlayers = game.playerIds.map((id) {
      try {
        return players.firstWhere((p) => p.id == id);
      } catch (_) {
        return null; // player deleted but game kept
      }
    }).toList();

    final dateStr =
        DateFormat('EEEE, MMMM d, yyyy').format(game.date);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              game.name.isEmpty ? 'Earth Game' : game.name,
              style:
                  tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(dateStr,
                style: tt.bodySmall?.copyWith(
                    color:
                        cs.onSurface.withValues(alpha: 0.6))),
          ],
        ),
        actions: [
          // Export
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Export',
            onPressed: () => _showExportSheet(context, game, gamePlayers),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete game',
            onPressed: () =>
                _confirmDelete(context, ref, game),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Winner banner ────────────────────────────────────────────────
          _WinnerBanner(game: game, gamePlayers: gamePlayers),

          // ── Metadata ─────────────────────────────────────────────────────
          if (game.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_outlined,
                      size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(game.notes,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.outline)),
                  ),
                ],
              ),
            ),

          // ── Mini leaderboard ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text('Standings',
                style: tt.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          _MiniLeaderboard(
              game: game, gamePlayers: gamePlayers),

          // ── Full comparison table ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Score Breakdown',
                style: tt.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          _ComparisonTable(
              game: game, gamePlayers: gamePlayers),
        ],
      ),
    );
  }

  void _showExportSheet(
      BuildContext context, Game game, List<Player?> players) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ExportSheet(game: game, players: players),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Game game) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete game?'),
        content: const Text(
            'This will permanently remove the game record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.error,
              foregroundColor:
                  Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gamesProvider.notifier).deleteGame(game.id);
              Navigator.of(context).pop(); // back to history
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Winner banner
// ─────────────────────────────────────────────────────────────────────────────

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner(
      {required this.game, required this.gamePlayers});
  final Game game;
  final List<Player?> gamePlayers;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final winners = game.winnerIds;
    final isTied  = winners.length > 1;
    final topScore = game.rankedScores.isEmpty
        ? 0
        : game.rankedScores.first.total;

    final winnerPlayers = gamePlayers
        .where((p) => p != null && winners.contains(p.id))
        .cast<Player>()
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTied
              ? [const Color(0xFF1565C0), const Color(0xFF0288D1)]
              : [const Color(0xFFB7940A), const Color(0xFFE6AC00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTied ? Icons.handshake : Icons.emoji_events,
              color: Colors.white, size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTied ? 'Tied for 1st' : 'Winner',
                  style: tt.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  winnerPlayers.map((p) => p.name).join(' & '),
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$topScore',
                style: tt.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('VP',
                  style: tt.labelSmall?.copyWith(
                      color:
                          Colors.white.withValues(alpha: 0.8))),
            ],
          ),

          // Avatars
          const SizedBox(width: 12),
          PlayerAvatarStack(
              players: winnerPlayers, size: 36, maxShown: 3),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini leaderboard
// ─────────────────────────────────────────────────────────────────────────────

class _MiniLeaderboard extends StatelessWidget {
  const _MiniLeaderboard(
      {required this.game, required this.gamePlayers});
  final Game game;
  final List<Player?> gamePlayers;

  @override
  Widget build(BuildContext context) {
    final ranked = game.rankedScores;
    return Column(
      children: ranked.map((score) {
        final player = gamePlayers
            .where((p) => p?.id == score.playerId)
            .firstOrNull;
        final rank = _rankOf(game, score.playerId);
        final isWinner = rank == 1;
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 3),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isWinner
                ? Colors.amber.withValues(alpha: 0.08)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWinner
                  ? Colors.amber.withValues(alpha: 0.4)
                  : cs.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  _ordinal(rank),
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isWinner
                        ? Colors.amber[700]
                        : cs.outline,
                  ),
                ),
              ),
              if (player != null)
                PlayerAvatar(player: player, size: 32)
              else
                const _PlaceholderAvatar(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  player?.name ?? 'Unknown',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: isWinner
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                '${score.total} VP',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isWinner
                      ? Colors.amber[800]
                      : cs.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full comparison table (horizontally scrollable)
// ─────────────────────────────────────────────────────────────────────────────

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable(
      {required this.game, required this.gamePlayers});

  final Game game;
  final List<Player?> gamePlayers;

  static const _labelW  = 148.0;
  static const _scoreW  = 66.0;
  static const _rowH    = 38.0;
  static const _headerH = 64.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final winners = game.winnerIds;

    // Ordered scores matching gamePlayers order
    final scores = game.playerIds
        .map((id) => game.scoreFor(id))
        .toList();

    Widget labelCell(String text,
        {bool bold = false, Color? color, Widget? leading}) {
      return SizedBox(
        width: _labelW,
        height: _rowH,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 6)],
              Expanded(
                child: Text(
                  text,
                  style: (bold ? tt.labelMedium : tt.bodySmall)
                      ?.copyWith(
                    fontWeight:
                        bold ? FontWeight.w800 : FontWeight.normal,
                    color: color ?? (bold ? cs.primary : cs.onSurface),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget scoreCell(String text,
        {bool bold = false,
        bool highlight = false,
        bool isZero = false,
        Color? accent}) {
      return Container(
        width: _scoreW,
        height: _rowH,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlight
              ? Colors.amber.withValues(alpha: 0.12)
              : null,
        ),
        child: Text(
          text,
          style: (bold ? tt.labelLarge : tt.bodySmall)?.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
            color: isZero
                ? cs.outlineVariant
                : (highlight ? Colors.amber[800] : accent ?? cs.onSurface),
          ),
        ),
      );
    }

    // ── Build rows ───────────────────────────────────────────────────────

    // Group headers — indices where a new group starts
    const groupAt = {0: 'Card VP', 4: 'Board Tokens',
        8: 'Ecosystem', 10: 'Fauna Board', 11: 'Special', 12: 'Other'};

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Corner cell
                  SizedBox(
                    width: _labelW,
                    height: _headerH,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Category',
                            style: tt.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                            )),
                      ),
                    ),
                  ),
                  // Player headers
                  for (var i = 0; i < game.playerIds.length; i++)
                    _PlayerHeaderCell(
                      player: gamePlayers[i],
                      isWinner: winners.contains(game.playerIds[i]),
                      width: _scoreW,
                      height: _headerH,
                    ),
                ],
              ),
            ),

            // ── Category rows ─────────────────────────────────────────────
            for (var ci = 0; ci < kEarthCategories.length; ci++) ...[
              // Group divider
              if (groupAt.containsKey(ci) && ci != 0)
                Container(
                  height: 1,
                  color: cs.outlineVariant,
                ),
              // Optional group label
              if (groupAt.containsKey(ci))
                Container(
                  width: _labelW +
                      _scoreW * game.playerIds.length,
                  height: 22,
                  color: cs.surfaceContainerLow,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    groupAt[ci]!.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

              // Data row
              _TableRow(
                index: ci,
                category: kEarthCategories[ci],
                labelW: _labelW,
                scoreW: _scoreW,
                rowH: _rowH,
                scores: scores,
                winners: winners,
                playerIds: game.playerIds,
              ),
            ],

            // ── Divider ───────────────────────────────────────────────────
            Container(height: 2, color: cs.outline),

            // ── Total row ─────────────────────────────────────────────────
            Row(
              children: [
                labelCell(
                  'TOTAL',
                  bold: true,
                  color: cs.primary,
                  leading: Icon(Icons.eco, size: 14, color: cs.primary),
                ),
                for (var i = 0; i < game.playerIds.length; i++)
                  scoreCell(
                    '${scores[i]?.total ?? 0}',
                    bold: true,
                    highlight: winners.contains(game.playerIds[i]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.index,
    required this.category,
    required this.labelW,
    required this.scoreW,
    required this.rowH,
    required this.scores,
    required this.winners,
    required this.playerIds,
  });

  final int index;
  final EarthCategory category;
  final double labelW, scoreW, rowH;
  final List<PlayerScore?> scores;
  final List<String> winners;
  final List<String> playerIds;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEven = index.isEven;

    return Container(
      color: isEven
          ? null
          : cs.surfaceContainerLow.withValues(alpha: 0.4),
      child: Row(
        children: [
          // Label
          SizedBox(
            width: labelW,
            height: rowH,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(category.icon,
                      size: 13, color: category.iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _short(category.label),
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Score cells
          for (var i = 0; i < playerIds.length; i++) ...[
            _buildScoreCell(i, cs, tt),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCell(int i, ColorScheme cs, TextTheme tt) {
    final score = scores[i];
    final v = score != null ? _valueFor(score, category.key) : 0;
    final isWinner = winners.contains(playerIds[i]);
    final isZero = v == 0;

    String label;
    if (category.isCheckbox) {
      label = score?.firstTableauComplete == true
          ? '+${score!.firstTableauBonusVp}'
          : '—';
    } else {
      label = isZero ? '—' : '$v';
    }

    return Container(
      width: scoreW,
      height: rowH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.amber.withValues(alpha: 0.06)
            : null,
        border: Border(
          left: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              width: 0.5),
        ),
      ),
      child: Text(
        label,
        style: tt.bodySmall?.copyWith(
          fontWeight: isZero ? FontWeight.normal : FontWeight.w600,
          color: isZero
              ? cs.outlineVariant
              : (isWinner ? Colors.amber[800] : cs.onSurface),
        ),
      ),
    );
  }

  static String _short(String label) {
    const map = {
      'Island Card VP': 'Island',
      'Climate Card VP': 'Climate',
      'Tableau Cards VP': 'Tableau',
      'Events VP': 'Events',
      'Terrain VP': 'Terrain',
      'Compost Cards': 'Compost',
      'Sprouts Remaining': 'Sprouts',
      'Growth / Trunks / Canopies': 'Growth',
      'Personal Ecosystem VP': 'Personal Eco',
      'Shared Ecosystem VP': 'Shared Eco',
      'Fauna Board VP': 'Fauna Board',
      'First 4×4 Tableau Complete': '4×4 Bonus',
      'Other / Bonus VP': 'Other',
    };
    return map[label] ?? label;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlayerHeaderCell extends StatelessWidget {
  const _PlayerHeaderCell({
    required this.player,
    required this.isWinner,
    required this.width,
    required this.height,
  });
  final Player? player;
  final bool isWinner;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.amber.withValues(alpha: 0.15)
            : null,
        border: Border(
          left: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              width: 0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isWinner)
            Icon(Icons.emoji_events,
                size: 12, color: Colors.amber[700]),
          if (player != null)
            PlayerAvatar(player: player!, size: 28)
          else
            const _PlaceholderAvatar(size: 28),
          const SizedBox(height: 2),
          Text(
            player?.name ?? '?',
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isWinner
                  ? Colors.amber[800]
                  : cs.onPrimaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle),
      child: Icon(Icons.person, size: size * 0.55, color: cs.outline),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.game, required this.players});
  final Game game;
  final List<Player?> players;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _loadingImage = false;
  bool _loadingCsv   = false;

  Future<void> _doExport(bool asImage) async {
    if (asImage) {
      setState(() => _loadingImage = true);
    } else {
      setState(() => _loadingCsv = true);
    }
    try {
      if (asImage) {
        await exportAsImage(
          context: context,
          game: widget.game,
          players: widget.players,
        );
      } else {
        await exportAsCsv(
          game: widget.game,
          players: widget.players,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _loadingImage = false; _loadingCsv = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final busy = _loadingImage || _loadingCsv;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('Export Game',
              style: tt.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            widget.game.name.isEmpty
                ? 'Earth Game'
                : widget.game.name,
            style: tt.bodyMedium?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 24),

          // Image option
          _ExportTile(
            icon: Icons.image_outlined,
            title: 'Share as Image',
            subtitle: 'Full scorecard as a PNG — great for sharing in chats',
            loading: _loadingImage,
            disabled: busy,
            onTap: () => _doExport(true),
          ),
          const SizedBox(height: 10),

          // CSV option
          _ExportTile(
            icon: Icons.table_chart_outlined,
            title: 'Export as CSV',
            subtitle: 'Spreadsheet file — open in Excel, Google Sheets, etc.',
            loading: _loadingCsv,
            disabled: busy,
            onTap: () => _doExport(false),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.outline)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}
