import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/player.dart';
import '../providers/players_provider.dart';
import '../providers/scoring_session_provider.dart';
import '../widgets/player_avatar.dart';
import '../widgets/player_form_dialog.dart';
import 'scoring_screen.dart';

class NewGameScreen extends ConsumerStatefulWidget {
  const NewGameScreen({super.key});

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  final _nameCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  static const _uuid = Uuid();

  final Set<String> _selected = {};
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  bool get _canStart => _selected.length >= 2 && _selected.length <= 6;

  void _toggle(String id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else if (_selected.length < 6) {
          _selected.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 6 players per game'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _startGame(List<Player> allPlayers) {
    if (!_canStart) return;

    // Preserve the tap order within the selected set
    final orderedIds = allPlayers
        .where((p) => _selected.contains(p.id))
        .map((p) => p.id)
        .toList();

    ref.read(scoringSessionProvider.notifier).startSession(
          gameId: _uuid.v4(),
          gameName: _nameCtrl.text.trim(),
          date: _date,
          notes: _notesCtrl.text.trim(),
          playerIds: orderedIds,
        );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScoringScreen()),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playersProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Game',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Section: select players ──────────────────────────────────
            _SectionHeader(
              icon: Icons.people,
              title: 'Select Players',
              subtitle: _selected.isEmpty
                  ? 'Choose 2–6 players'
                  : '${_selected.length} selected',
              subtitleColor:
                  _selected.length < 2 ? cs.outline : cs.primary,
            ),
            const SizedBox(height: 8),

            if (players.isEmpty)
              _NoPlayersCard(
                onAdd: () async {
                  await showPlayerForm(context);
                },
              )
            else
              ...players.map((p) => _PlayerSelectTile(
                    player: p,
                    selected: _selected.contains(p.id),
                    onTap: () => _toggle(p.id),
                  )),

            // ── Add player shortcut ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: OutlinedButton.icon(
                onPressed: () => showPlayerForm(context),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add a player'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section: game details ────────────────────────────────────
            const _SectionHeader(
              icon: Icons.info_outline,
              title: 'Game Details',
              subtitle: 'Optional',
            ),
            const SizedBox(height: 10),

            // Game name
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Game name',
                hintText: 'e.g. Friday Night Earth',
                prefixIcon: Icon(Icons.label_outline),
              ),
              maxLength: 40,
            ),
            const SizedBox(height: 10),

            // Date picker
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
              ),
              leading: Icon(Icons.calendar_today, color: cs.primary),
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'House rules, expansion in use, etc.',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),

      // ── Start button ───────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selected player avatars strip
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectedStrip(
                    players: players
                        .where((p) => _selected.contains(p.id))
                        .toList(),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _canStart ? () => _startGame(players) : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _canStart
                        ? 'Start Scoring'
                        : _selected.length < 2
                            ? 'Select at least 2 players'
                            : 'Too many players (max 6)',
                    style: const TextStyle(fontSize: 16),
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            '· $subtitle',
            style: tt.bodySmall?.copyWith(
              color: subtitleColor ?? cs.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlayerSelectTile extends StatelessWidget {
  const _PlayerSelectTile({
    required this.player,
    required this.selected,
    required this.onTap,
  });
  final Player player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected
            ? cs.primaryContainer.withValues(alpha: 0.6)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              PlayerAvatar(player: player, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  player.name,
                  style: tt.titleSmall?.copyWith(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? Icon(Icons.check_circle,
                        key: const ValueKey('on'),
                        color: cs.primary,
                        size: 24)
                    : Icon(Icons.radio_button_unchecked,
                        key: const ValueKey('off'),
                        color: cs.outlineVariant,
                        size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SelectedStrip extends StatelessWidget {
  const _SelectedStrip({required this.players});
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayerAvatarStack(players: players, size: 32, maxShown: 6),
        const SizedBox(width: 10),
        Text(
          '${players.length} player${players.length == 1 ? '' : 's'} selected',
          style: tt.bodySmall?.copyWith(color: cs.outline),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NoPlayersCard extends StatelessWidget {
  const _NoPlayersCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: cs.outline),
          const SizedBox(height: 10),
          Text(
            'No players yet',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Add players before starting a game.',
            style: tt.bodySmall?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add Player'),
          ),
        ],
      ),
    );
  }
}
