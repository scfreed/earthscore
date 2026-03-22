import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/scoring_session_provider.dart';
import '../widgets/player_avatar.dart';
import '../providers/players_provider.dart';

/// Compact tab label: avatar + name + live running total.
class PlayerTabLabel extends ConsumerWidget {
  const PlayerTabLabel({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerByIdProvider(playerId));
    final total  = ref.watch(playerLiveTotalProvider(playerId));
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;

    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player != null) PlayerAvatar(player: player, size: 26),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player?.name ?? 'Player',
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '$total pts',
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Large total card shown at the top of each player's scoring form.
class LiveTotalCard extends ConsumerWidget {
  const LiveTotalCard({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerByIdProvider(playerId));
    final total  = ref.watch(playerLiveTotalProvider(playerId));
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    const kMax   = 300.0; // reference ceiling for the progress bar

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (player != null) PlayerAvatar(player: player, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player?.name ?? 'Player',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Running total',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              Text(
                '$total',
                style: tt.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'VP',
                style: tt.labelLarge?.copyWith(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (total / kMax).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  cs.onPrimaryContainer.withValues(alpha: 0.15),
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
