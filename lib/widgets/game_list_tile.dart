import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/game.dart';
import '../providers/players_provider.dart';
import '../screens/game_detail_screen.dart';
import 'player_avatar.dart';

class GameListTile extends ConsumerWidget {
  const GameListTile({super.key, required this.game, this.showDivider = true});

  final Game game;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playersProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final gamePlayers = game.playerIds
        .map((id) {
          try {
            return players.firstWhere((p) => p.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Object>()
        .toList();

    final ranked = game.rankedScores;
    final winners = game.winnerIds;
    final winnerName = winners.length == 1
        ? players
            .where((p) => p.id == winners.first)
            .map((p) => p.name)
            .firstOrNull
        : null;

    final topScore = ranked.isEmpty ? 0 : ranked.first.total;
    final dateStr = DateFormat('MMM d, yyyy').format(game.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailScreen(gameId: game.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Trophy / rank icon ───────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  winners.length > 1 ? Icons.handshake : Icons.emoji_events,
                  color: cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // ── Details ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game name / date
                    Text(
                      game.name.isEmpty ? 'Earth Game' : game.name,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(dateStr, style: tt.bodySmall?.copyWith(color: cs.outline)),
                    const SizedBox(height: 6),

                    // Winner line
                    if (winnerName != null)
                      Row(
                        children: [
                          Icon(Icons.star, size: 13, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '$winnerName · $topScore pts',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else if (winners.length > 1)
                      Text(
                        'Tie · $topScore pts',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              // ── Avatar stack ─────────────────────────────────────────────
              if (gamePlayers.isNotEmpty) ...[
                const SizedBox(width: 8),
                // ignore: avoid_dynamic_calls — safe cast above
                PlayerAvatarStack(
                  players: gamePlayers.cast(),
                  size: 28,
                  maxShown: 4,
                ),
              ],

              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: cs.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}
