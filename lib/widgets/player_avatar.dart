import 'package:flutter/material.dart';
import '../models/player.dart';

/// Coloured circle showing the player's initials.
/// [size] is the diameter in logical pixels.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.player,
    this.size = 40,
    this.fontSize,
    this.showBorder = false,
  });

  final Player player;
  final double size;
  final double? fontSize;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final fg = _foreground(player.color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: player.color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: player.color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          player.initials,
          style: TextStyle(
            color: fg,
            fontSize: fontSize ?? size * 0.38,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Pick white or black text depending on background luminance.
  static Color _foreground(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.45 ? Colors.black87 : Colors.white;
  }
}

/// A row of overlapping avatars (like a group photo strip).
class PlayerAvatarStack extends StatelessWidget {
  const PlayerAvatarStack({
    super.key,
    required this.players,
    this.size = 32,
    this.maxShown = 4,
  });

  final List<Player> players;
  final double size;
  final int maxShown;

  @override
  Widget build(BuildContext context) {
    final shown = players.take(maxShown).toList();
    final extra = players.length - shown.length;
    final overlap = size * 0.35;

    return SizedBox(
      height: size,
      width: shown.length * (size - overlap) + overlap +
          (extra > 0 ? size * 0.8 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: PlayerAvatar(player: shown[i], size: size, showBorder: true),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * (size - overlap),
              child: _ExtraChip(count: extra, size: size),
            ),
        ],
      ),
    );
  }
}

class _ExtraChip extends StatelessWidget {
  const _ExtraChip({required this.count, required this.size});
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.8,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
