import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game.dart';
import '../models/player_score.dart';
import '../providers/games_provider.dart';
import '../providers/players_provider.dart';
import '../providers/scoring_session_provider.dart';
import '../utils/earth_categories.dart';
import '../widgets/player_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Ranked {
  final int rank;
  final String playerId;
  final PlayerScore score;
  final bool isTied;

  const _Ranked({
    required this.rank,
    required this.playerId,
    required this.score,
    required this.isTied,
  });
}

List<_Ranked> _computeRankings(ScoringSession session) {
  final scores = session.playerIds.map((id) => session.scoreFor(id)).toList();
  scores.sort((a, b) => b.total.compareTo(a.total));

  return scores.map((s) {
    final rank = scores.where((x) => x.total > s.total).length + 1;
    final isTied = scores.where((x) => x.total == s.total).length > 1;
    return _Ranked(
        rank: rank, playerId: s.playerId, score: s, isTied: isTied);
  }).toList();
}

int _valueFor(PlayerScore s, String key) {
  switch (key) {
    case 'cardsVp':        return s.cardsVp;
    case 'sproutsVp':      return s.sproutsVp;
    case 'growthVp':       return s.growthVp;
    case 'terrainVp':      return s.terrainVp;
    case 'personalEcoVp':  return s.personalEcoVp;
    case 'sharedEco1Vp':   return s.sharedEco1Vp;
    case 'sharedEco2Vp':   return s.sharedEco2Vp;
    case 'compostCards':   return s.compostCards;
    case 'eventsVp':       return s.eventsVp;
    case 'faunaBoardVp':   return s.faunaBoardVp;
    default:              return 0;
  }
}

String _ordinal(int n) {
  if (n == 1) return '1st';
  if (n == 2) return '2nd';
  if (n == 3) return '3rd';
  return '${n}th';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ScoreSummaryScreen extends ConsumerStatefulWidget {
  const ScoreSummaryScreen({super.key});

  @override
  ConsumerState<ScoreSummaryScreen> createState() =>
      _ScoreSummaryScreenState();
}

class _ScoreSummaryScreenState extends ConsumerState<ScoreSummaryScreen> {
  bool _saving = false;

  Future<void> _saveAndFinish(ScoringSession session) async {
    setState(() => _saving = true);
    try {
      final scores =
          session.playerIds.map((id) => session.scoreFor(id)).toList();

      final game = Game(
        id: session.gameId,
        name: session.gameName,
        dateMs: session.date.millisecondsSinceEpoch,
        notes: session.notes,
        playerIds: session.playerIds,
        scores: scores,
      );

      ref.read(gamesProvider.notifier).saveGame(game);
      ref.read(scoringSessionProvider.notifier).clearSession();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save game: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scoringSessionProvider);

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.of(context).maybePop());
      return const SizedBox.shrink();
    }

    final ranked = _computeRankings(session);
    final winners = ranked.where((r) => r.rank == 1).toList();
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Final Scores',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (session.gameName.isNotEmpty)
              Text(session.gameName,
                  style: tt.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6))),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Winner hero ──────────────────────────────────────────────────
          _WinnerSection(winners: winners, ref: ref),
          const SizedBox(height: 8),

          // ── Full leaderboard ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text('Standings',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (final r in ranked)
            _LeaderboardTile(ranked: r, ref: ref),

          const SizedBox(height: 16),

          // ── Score breakdown ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('Score Breakdown',
                style: tt.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (final r in ranked)
            _BreakdownTile(
              ranked: r,
              ref: ref,
              initiallyExpanded: r.rank == 1,
            ),
        ],
      ),

      // ── Save bar ─────────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Discard — go back to scoring to edit
              OutlinedButton.icon(
                onPressed:
                    _saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _saving ? null : () => _saveAndFinish(session),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_saving ? 'Saving…' : 'Save & Finish'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Winner hero section
// ─────────────────────────────────────────────────────────────────────────────

class _WinnerSection extends StatelessWidget {
  const _WinnerSection({required this.winners, required this.ref});
  final List<_Ranked> winners;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isTied = winners.length > 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTied
              ? [const Color(0xFF1565C0), const Color(0xFF0288D1)]
              : [const Color(0xFFB7940A), const Color(0xFFE6AC00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isTied ? Colors.blue : Colors.amber)
                .withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isTied ? Icons.handshake : Icons.emoji_events,
                  color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                isTied
                    ? 'Tied for 1st!'
                    : '🏆  Winner',
                style: tt.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // One or more winner avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final w in winners) ...[
                _WinnerAvatar(ranked: w, ref: ref),
                if (w != winners.last) const SizedBox(width: 24),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WinnerAvatar extends StatelessWidget {
  const _WinnerAvatar({required this.ranked, required this.ref});
  final _Ranked ranked;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerByIdProvider(ranked.playerId));
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (player != null)
              PlayerAvatar(player: player, size: 68, showBorder: true)
            else
              const _UnknownAvatar(size: 68),
            const Positioned(
              top: -10,
              right: -6,
              child: Icon(Icons.stars, color: Colors.white, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          player?.name ?? 'Player',
          style: tt.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${ranked.score.total} VP',
          style: tt.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaderboard row
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.ranked, required this.ref});
  final _Ranked ranked;
  final WidgetRef ref;

  static const _medalColors = [
    Color(0xFFFFB300), // gold  – 1st
    Color(0xFF90A4AE), // silver – 2nd
    Color(0xFFBF8970), // bronze – 3rd
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerByIdProvider(ranked.playerId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isTop3 = ranked.rank <= 3;
    final medalColor =
        isTop3 ? _medalColors[ranked.rank - 1] : cs.outlineVariant;
    final isWinner = ranked.rank == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.amber.withValues(alpha: 0.08)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner
              ? Colors.amber.withValues(alpha: 0.4)
              : cs.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Text(
                  _ordinal(ranked.rank),
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: medalColor,
                  ),
                ),
                if (ranked.isTied)
                  Text(
                    'tied',
                    style: tt.labelSmall?.copyWith(
                      color: cs.outline,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          if (player != null)
            PlayerAvatar(player: player, size: 36)
          else
            const _UnknownAvatar(size: 36),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              player?.name ?? 'Unknown',
              style: tt.titleSmall?.copyWith(
                fontWeight:
                    isWinner ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),

          // Score
          Text(
            '${ranked.score.total}',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isWinner ? Colors.amber[800] : cs.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text('VP',
              style: tt.bodySmall?.copyWith(color: cs.outline)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-player score breakdown (expandable)
// ─────────────────────────────────────────────────────────────────────────────

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({
    required this.ranked,
    required this.ref,
    this.initiallyExpanded = false,
  });

  final _Ranked ranked;
  final WidgetRef ref;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerByIdProvider(ranked.playerId));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final score = ranked.score;

    final rows = kEarthCategories.map((cat) {
      final v = _valueFor(score, cat.key);
      return (category: cat, value: v);
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: player != null
            ? PlayerAvatar(player: player, size: 36)
            : const _UnknownAvatar(size: 36),
        title: Text(
          player?.name ?? 'Player',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${score.total} VP total',
          style: tt.bodySmall?.copyWith(color: cs.primary),
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Category rows
          for (final row in rows)
            _BreakdownRow(
              category: row.category,
              value: row.value,
              note: null,
            ),
          const Divider(height: 16),
          // Total row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.eco, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('TOTAL',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: 1,
                      )),
                ),
                Text(
                  '${score.total} VP',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.category,
    required this.value,
    this.note,
  });

  final EarthCategory category;
  final int value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isZero = value == 0;
    final labelColor = isZero ? cs.outline : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                category.icon,
                size: 16,
                color: isZero
                    ? cs.outlineVariant
                    : category.iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: tt.bodySmall?.copyWith(color: labelColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isZero
                      ? Colors.transparent
                      : category.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category.isCheckbox
                      ? (value > 0 ? '+$value' : '—')
                      : (isZero ? '—' : '$value'),
                  style: tt.labelMedium?.copyWith(
                    fontWeight:
                        isZero ? FontWeight.normal : FontWeight.w700,
                    color: isZero ? cs.outlineVariant : category.iconColor,
                  ),
                ),
              ),
            ],
          ),
          if (note != null && note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                note!,
                style: tt.bodySmall
                    ?.copyWith(color: cs.outline, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback when player record is missing
// ─────────────────────────────────────────────────────────────────────────────

class _UnknownAvatar extends StatelessWidget {
  const _UnknownAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: size * 0.55, color: cs.outline),
    );
  }
}
