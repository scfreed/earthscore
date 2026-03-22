import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/scoring_session_provider.dart';
import '../utils/earth_categories.dart';
import '../widgets/category_row.dart';
import '../widgets/score_chip.dart';
import 'score_summary_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Category groups — maps first index in each group to its label
// ─────────────────────────────────────────────────────────────────────────────
const _kGroups = <int, String>{
  0: 'Card VP',              // index 0: Cards VP
  1: 'Growth',               // indices 1–2: Sprouts, Trunks/Canopy
  3: 'Terrain',              // index 3: Terrain VP
  4: 'Ecosystem Objectives', // indices 4–6: Personal Eco, Shared Eco 1, Shared Eco 2
  7: 'Compost & Events',     // indices 7–8: Compost, Events VP
  9: 'Fauna Board',          // index 9: Fauna Board VP
};

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class ScoringScreen extends ConsumerWidget {
  const ScoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(scoringSessionProvider);

    // Guard: if session was cleared navigate back.
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.of(context).maybePop());
      return const SizedBox.shrink();
    }

    final playerCount = session.playerIds.length;

    return DefaultTabController(
      length: playerCount,
      child: Scaffold(
        appBar: AppBar(
          title: _AppBarTitle(session: session),
          actions: [
            _FinishButton(session: session),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: playerCount > 3,
            tabAlignment: playerCount > 3
                ? TabAlignment.start
                : TabAlignment.fill,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: session.playerIds
                .map((id) => PlayerTabLabel(playerId: id))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: session.playerIds
              .map((id) => _PlayerScoreForm(playerId: id))
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.session});
  final ScoringSession session;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final name = session.gameName.isEmpty ? 'Scoring' : session.gameName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(
          '${session.playerIds.length} players · tap ℹ for help',
          style: tt.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FinishButton extends ConsumerWidget {
  const _FinishButton({required this.session});
  final ScoringSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () => _confirmFinish(context),
      icon: const Icon(Icons.check_rounded, size: 18),
      label: const Text('Finish'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _confirmFinish(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.sports_score),
        title: const Text('Finish game?'),
        content: const Text(
            'Review scores before saving. You can still go back to edit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ScoreSummaryScreen()),
              );
            },
            child: const Text('See results'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-player scrollable form
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerScoreForm extends ConsumerWidget {
  const _PlayerScoreForm({required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // ── Live total hero ────────────────────────────────────────────────
        LiveTotalCard(playerId: playerId),

        // ── Scoring categories ─────────────────────────────────────────────
        for (var i = 0; i < kEarthCategories.length; i++) ...[
          if (_kGroups.containsKey(i))
            CategoryGroupHeader(label: _kGroups[i]!),
          CategoryRow(
            key: ValueKey('$playerId-${kEarthCategories[i].key}'),
            category: kEarthCategories[i],
            playerId: playerId,
          ),
        ],
      ],
    );
  }
}

