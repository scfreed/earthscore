import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/game.dart';
import '../providers/games_provider.dart';
import '../providers/players_provider.dart';
import '../widgets/game_list_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local search provider
// ─────────────────────────────────────────────────────────────────────────────

final _searchQueryProvider = StateProvider<String>((ref) => '');

// ─────────────────────────────────────────────────────────────────────────────

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
    if (!_showSearch) {
      _searchCtrl.clear();
      ref.read(_searchQueryProvider.notifier).state = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGames = ref.watch(gamesProvider);
    final query    = ref.watch(_searchQueryProvider);
    final players  = ref.watch(playersProvider);
    final cs       = Theme.of(context).colorScheme;
    final tt       = Theme.of(context).textTheme;

    // ── Filter ───────────────────────────────────────────────────────────────
    final filtered = query.isEmpty
        ? allGames
        : allGames.where((g) {
            final q = query.toLowerCase();
            if (g.name.toLowerCase().contains(q)) return true;
            return g.playerIds.any((id) {
              final p = players.where((p) => p.id == id).firstOrNull;
              return p?.name.toLowerCase().contains(q) ?? false;
            });
          }).toList();

    // ── Group by month ────────────────────────────────────────────────────────
    final grouped = _groupByMonth(filtered);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search games or players…',
                  border: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                style: tt.bodyLarge,
                onChanged: (v) =>
                    ref.read(_searchQueryProvider.notifier).state = v,
              )
            : Text('History',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: allGames.isEmpty
          ? _EmptyState()
          : filtered.isEmpty
              ? _NoResults(query: query)
              : CustomScrollView(
                  slivers: [
                    // Stats strip
                    SliverToBoxAdapter(
                      child: _StatsStrip(total: allGames.length),
                    ),

                    for (final entry in grouped.entries) ...[
                      // Month header
                      SliverToBoxAdapter(
                        child: _MonthHeader(label: entry.key),
                      ),
                      // Game tiles
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _DismissibleGameTile(
                              game: entry.value[i]),
                          childCount: entry.value.length,
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(
                        child: SizedBox(height: 40)),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Map<String, List<Game>> _groupByMonth(List<Game> games) {
  final result = <String, List<Game>>{};
  for (final g in games) {
    final key = DateFormat('MMMM yyyy').format(g.date);
    (result[key] ??= []).add(g);
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Text(
        '$total game${total == 1 ? '' : 's'} recorded',
        style: tt.bodySmall?.copyWith(color: cs.outline),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DismissibleGameTile extends ConsumerWidget {
  const _DismissibleGameTile({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(game.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, game.name),
      onDismissed: (_) {
        ref.read(gamesProvider.notifier).deleteGame(game.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${game.name.isEmpty ? 'Game' : game.name} deleted'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      child: GameListTile(game: game),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    final label = name.isEmpty ? 'this game' : '"$name"';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Delete $label?'),
        content: const Text('This will permanently remove the game record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 52, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text('No games yet',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Finished games will appear here.\nStart a new game from the Home tab.',
              style: tt.bodyMedium?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: cs.outline),
            const SizedBox(height: 16),
            Text('No results for "$query"',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Try a different game name or player name.',
                style: tt.bodyMedium?.copyWith(color: cs.outline),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
