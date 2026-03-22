import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../providers/games_provider.dart';
import '../providers/players_provider.dart';
import '../widgets/player_avatar.dart';
import '../widgets/player_form_dialog.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playersProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Players', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              onPressed: () => showPlayerForm(context),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add'),
            ),
          ),
        ],
      ),

      body: players.isEmpty
          ? _EmptyState(onAdd: () => showPlayerForm(context))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: players.length,
              itemBuilder: (_, i) => _PlayerTile(player: players[i]),
            ),

      floatingActionButton: players.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => showPlayerForm(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player'),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlayerTile extends ConsumerWidget {
  const _PlayerTile({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final gamesPlayed = games.where((g) => g.playerIds.contains(player.id)).length;
    final wins = games.where((g) => g.winnerIds.contains(player.id)).length;

    return Dismissible(
      key: ValueKey(player.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, player.name, gamesPlayed),
      onDismissed: (_) {
        ref.read(playersProvider.notifier).deletePlayer(player.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${player.name} removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showPlayerForm(context, existing: player),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar
                PlayerAvatar(player: player, size: 48),
                const SizedBox(width: 14),

                // Name + stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatBadge(
                            icon: Icons.sports_esports,
                            label: '$gamesPlayed game${gamesPlayed == 1 ? '' : 's'}',
                          ),
                          const SizedBox(width: 8),
                          if (gamesPlayed > 0)
                            _StatBadge(
                              icon: Icons.emoji_events,
                              label: '$wins win${wins == 1 ? '' : 's'}',
                              highlight: wins > 0,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => showPlayerForm(context, existing: player),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, String name, int gamesPlayed) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Remove $name?'),
        content: gamesPlayed > 0
            ? Text(
                '$name has played $gamesPlayed game${gamesPlayed == 1 ? '' : 's'}. '
                'Their game history will be kept, but they will be removed from '
                'the players list.',
              )
            : const Text('This action cannot be undone.'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = highlight ? Colors.amber[700]! : cs.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people, size: 52, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No players yet',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add the people who play Earth with you.\nYou can have up to 5–6 players.',
              style: tt.bodyMedium?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add),
              label: const Text('Add First Player'),
            ),
          ],
        ),
      ),
    );
  }
}
