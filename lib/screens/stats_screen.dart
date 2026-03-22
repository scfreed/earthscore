import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../providers/games_provider.dart';
import '../providers/players_provider.dart';
import '../utils/score_calculator.dart';
import '../widgets/player_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sort options
// ─────────────────────────────────────────────────────────────────────────────

enum _SortBy { winRate, avgScore, gamesPlayed, highScore }

const _sortLabels = {
  _SortBy.winRate:    'Win rate',
  _SortBy.avgScore:   'Avg score',
  _SortBy.gamesPlayed:'Games played',
  _SortBy.highScore:  'High score',
};

final _sortProvider = StateProvider<_SortBy>((ref) => _SortBy.winRate);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players  = ref.watch(playersProvider);
    final games    = ref.watch(gamesProvider);
    final sortBy   = ref.watch(_sortProvider);
    final tt       = Theme.of(context).textTheme;

    if (players.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline,
        title: 'No players yet',
        body: 'Add players and play some games — your stats will appear here.',
      );
    }

    if (games.isEmpty) {
      return const _EmptyState(
        icon: Icons.bar_chart,
        title: 'No games yet',
        body: 'Finish and save a game to see your statistics.',
      );
    }

    // Compute stats for every player
    final statsList = players
        .map((p) => (player: p, stats: computeStats(p, games)))
        .toList();

    // Sort
    statsList.sort((a, b) {
      switch (sortBy) {
        case _SortBy.winRate:
          final c = b.stats.winRate.compareTo(a.stats.winRate);
          return c != 0 ? c : b.stats.avgScore.compareTo(a.stats.avgScore);
        case _SortBy.avgScore:
          return b.stats.avgScore.compareTo(a.stats.avgScore);
        case _SortBy.gamesPlayed:
          return b.stats.gamesPlayed.compareTo(a.stats.gamesPlayed);
        case _SortBy.highScore:
          return b.stats.highScore.compareTo(a.stats.highScore);
      }
    });

    // Overall summary values
    final totalGames  = games.length;
    final highestEver = statsList
        .map((e) => e.stats.highScore)
        .fold(0, (a, b) => a > b ? a : b);
    final mostActive  = statsList
        .where((e) => e.stats.gamesPlayed > 0)
        .fold<({Player player, int games})?>(null, (best, e) {
          if (best == null || e.stats.gamesPlayed > best.games) {
            return (player: e.player, games: e.stats.gamesPlayed);
          }
          return best;
        });

    return Scaffold(
      appBar: AppBar(
        title: Text('Stats',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Summary strip ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SummaryStrip(
              totalGames: totalGames,
              totalPlayers: players.length,
              highestEver: highestEver,
              mostActiveName: mostActive?.player.name,
            ),
          ),

          // ── Podium (top 3 by current sort) ────────────────────────────
          if (statsList.length >= 2)
            SliverToBoxAdapter(
              child: _Podium(top: statsList.take(3).toList(), sortBy: sortBy),
            ),

          // ── Sort chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _SortBar(current: sortBy, ref: ref)),

          // ── Per-player cards ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final entry = statsList[i];
                  return _PlayerStatCard(
                    rank: i + 1,
                    player: entry.player,
                    stats: entry.stats,
                    sortBy: sortBy,
                    totalGames: totalGames,
                  );
                },
                childCount: statsList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary strip
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.totalGames,
    required this.totalPlayers,
    required this.highestEver,
    required this.mostActiveName,
  });

  final int totalGames;
  final int totalPlayers;
  final int highestEver;
  final String? mostActiveName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _SummaryItem(icon: Icons.sports_esports,  label: 'Games',       value: '$totalGames')),
          _Vdivider(),
          Expanded(child: _SummaryItem(icon: Icons.people,          label: 'Players',     value: '$totalPlayers')),
          _Vdivider(),
          Expanded(child: _SummaryItem(icon: Icons.workspace_premium, label: 'Record',    value: '$highestEver VP')),
          if (mostActiveName != null) ...[
            _Vdivider(),
            Expanded(child: _SummaryItem(icon: Icons.local_fire_department, label: 'Most active', value: mostActiveName!, compact: true)),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onPrimaryContainer,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          label,
          style: tt.labelSmall
              ?.copyWith(color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context)
          .colorScheme
          .onPrimaryContainer
          .withValues(alpha: 0.2),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Podium — top 3 players
// ─────────────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.top, required this.sortBy});
  final List<({Player player, PlayerStats stats})> top;
  final _SortBy sortBy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Order: 2nd (left), 1st (centre), 3rd (right)
    final ordered = [
      if (top.length >= 2) (entry: top[1], rank: 2),
      (entry: top[0], rank: 1),
      if (top.length >= 3) (entry: top[2], rank: 3),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ordered.map((item) {
          final isFirst  = item.rank == 1;
          final podHeight = isFirst ? 56.0 : (item.rank == 2 ? 40.0 : 28.0);
          final avatarSz  = isFirst ? 52.0 : 40.0;
          final medal     = ['🥇', '🥈', '🥉'][item.rank - 1];

          String primaryStat() {
            final s = item.entry.stats;
            switch (sortBy) {
              case _SortBy.winRate:
                return '${(s.winRate * 100).round()}%';
              case _SortBy.avgScore:
                return '${s.avgScore.round()} avg';
              case _SortBy.gamesPlayed:
                return '${s.gamesPlayed} games';
              case _SortBy.highScore:
                return '${s.highScore} best';
            }
          }

          return Expanded(
            child: Column(
              children: [
                Text(medal, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                PlayerAvatar(
                    player: item.entry.player,
                    size: avatarSz,
                    showBorder: isFirst),
                const SizedBox(height: 4),
                Text(
                  item.entry.player.name,
                  style: tt.labelMedium?.copyWith(
                    fontWeight:
                        isFirst ? FontWeight.w800 : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  primaryStat(),
                  style: tt.labelSmall
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Container(
                  height: podHeight,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? cs.primary
                        : cs.primaryContainer,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text(
                      '${item.rank}',
                      style: TextStyle(
                        color: isFirst
                            ? cs.onPrimary
                            : cs.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                        fontSize: isFirst ? 18 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort bar
// ─────────────────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  const _SortBar({required this.current, required this.ref});
  final _SortBy current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text('Sort by:',
              style: tt.bodySmall?.copyWith(color: cs.outline)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _SortBy.values.map((s) {
                  final selected = s == current;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_sortLabels[s]!),
                      selected: selected,
                      onSelected: (_) =>
                          ref.read(_sortProvider.notifier).state = s,
                      showCheckmark: false,
                      labelStyle: tt.labelSmall?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player stat card
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerStatCard extends StatelessWidget {
  const _PlayerStatCard({
    required this.rank,
    required this.player,
    required this.stats,
    required this.sortBy,
    required this.totalGames,
  });

  final int rank;
  final Player player;
  final PlayerStats stats;
  final _SortBy sortBy;
  final int totalGames;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final noGames = stats.gamesPlayed == 0;
    final winPct  = (stats.winRate * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                // Rank badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? [
                            Colors.amber,
                            Colors.blueGrey.shade300,
                            const Color(0xFFBF8970),
                          ][rank - 1]
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: rank <= 3 ? Colors.white : cs.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                PlayerAvatar(player: player, size: 44),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name,
                          style: tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        noGames
                            ? 'No games recorded'
                            : '${stats.gamesPlayed} game${stats.gamesPlayed == 1 ? '' : 's'} played',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ],
                  ),
                ),

                // Win rate badge
                if (!noGames)
                  _WinRateBadge(
                    wins: stats.wins,
                    ties: stats.ties,
                    pct: winPct,
                  ),
              ],
            ),

            if (noGames) const SizedBox(height: 4),
            if (noGames)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Play some games to see stats here.',
                  style: tt.bodySmall?.copyWith(color: cs.outline),
                ),
              ),

            if (!noGames) ...[
              const SizedBox(height: 12),

              // ── Win-rate bar ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stats.winRate,
                        minHeight: 7,
                        backgroundColor:
                            cs.surfaceContainerHighest,
                        color: player.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$winPct%',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      )),
                ],
              ),
              const SizedBox(height: 12),

              // ── Stat row ──────────────────────────────────────────────
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.emoji_events,
                    value: '${stats.wins}',
                    label: 'Wins',
                    color: Colors.amber[700]!,
                  ),
                  _MiniStat(
                    icon: Icons.handshake,
                    value: '${stats.ties}',
                    label: 'Ties',
                    color: cs.primary,
                  ),
                  _MiniStat(
                    icon: Icons.show_chart,
                    value: stats.avgScore.toStringAsFixed(1),
                    label: 'Avg VP',
                    color: cs.secondary,
                  ),
                  _MiniStat(
                    icon: Icons.arrow_upward,
                    value: '${stats.highScore}',
                    label: 'Best',
                    color: Colors.green[700]!,
                  ),
                  _MiniStat(
                    icon: Icons.arrow_downward,
                    value: '${stats.lowScore}',
                    label: 'Worst',
                    color: cs.outline,
                  ),
                ],
              ),

              // ── Participation bar ─────────────────────────────────────
              if (totalGames > 0 && stats.gamesPlayed < totalGames) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.sports_esports,
                        size: 12, color: cs.outline),
                    const SizedBox(width: 4),
                    Text(
                      'Participated in ${stats.gamesPlayed} of $totalGames games',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.outline),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WinRateBadge extends StatelessWidget {
  const _WinRateBadge({
    required this.wins,
    required this.ties,
    required this.pct,
  });
  final int wins;
  final int ties;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pct >= 50
            ? Colors.amber.withValues(alpha: 0.15)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: pct >= 50
              ? Colors.amber.withValues(alpha: 0.5)
              : cs.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: pct >= 50 ? Colors.amber[800] : cs.onSurface,
            ),
          ),
          Text(
            'win rate',
            style: tt.labelSmall?.copyWith(color: cs.outline),
          ),
          if (wins > 0 || ties > 0)
            Text(
              '${wins}W ${ties}T',
              style: tt.labelSmall?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          Text(value,
              style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: cs.onSurface)),
          Text(label,
              style: tt.labelSmall
                  ?.copyWith(color: cs.outline, fontSize: 9)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Stats',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: cs.primary),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: tt.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(body,
                  style: tt.bodyMedium?.copyWith(color: cs.outline),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
