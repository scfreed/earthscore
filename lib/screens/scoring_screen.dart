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
  0:  'Card VP',           // indices 0–3: Island, Climate, Tableau, Events
  4:  'Tokens & Growth',  // indices 4–7: Compost, Sprouts, Trunks/Canopy, Terrain
  8:  'Ecosystem Objectives', // indices 8–10: Personal Eco, Shared Eco, First Tableau
  11: 'Fauna Board',      // index 11: Fauna Board VP
  12: 'Other',            // index 12: Other VP
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
    final score = ref.watch(playerLiveScoreProvider(playerId));
    final notifier = ref.read(scoringSessionProvider.notifier);

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
          // Extra note field for the "other" row
          if (kEarthCategories[i].key == 'otherVp')
            _OtherNoteField(
              playerId: playerId,
              initialValue: score?.otherNote ?? '',
              onChanged: (v) => notifier.updateOtherNote(playerId, v),
            ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Other" free-text note field
// ─────────────────────────────────────────────────────────────────────────────

class _OtherNoteField extends StatefulWidget {
  const _OtherNoteField({
    required this.playerId,
    required this.initialValue,
    required this.onChanged,
  });
  final String playerId;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_OtherNoteField> createState() => _OtherNoteFieldState();
}

class _OtherNoteFieldState extends State<_OtherNoteField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          hintText: 'e.g. "Promo card +3 VP"',
          prefixIcon: Icon(Icons.notes_outlined, size: 18),
        ),
        maxLength: 100,
        maxLines: 2,
        onChanged: widget.onChanged,
      ),
    );
  }
}
