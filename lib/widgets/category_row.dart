import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_score.dart';
import '../providers/scoring_session_provider.dart';
import '../utils/earth_categories.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

/// One row in the scoring form for [category] and [playerId].
class CategoryRow extends ConsumerWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.playerId,
  });

  final EarthCategory category;
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(playerLiveScoreProvider(playerId));
    final notifier = ref.read(scoringSessionProvider.notifier);

    final value = _getInt(score, category.key);
    return _NumberRow(
      category: category,
      value: value,
      onChanged: (v) => notifier.updateField(playerId, category.key, v),
    );
  }

  static int _getInt(PlayerScore? s, String key) {
    if (s == null) return 0;
    switch (key) {
      case 'cardsVp':       return s.cardsVp;
      case 'sproutsVp':     return s.sproutsVp;
      case 'trunksVp':      return s.trunksVp;
      case 'canopyVp':      return s.canopyVp;
      case 'terrainVp':     return s.terrainVp;
      case 'personalEcoVp': return s.personalEcoVp;
      case 'sharedEcoVp':   return s.sharedEcoVp;
      case 'compostCards':  return s.compostCards;
      case 'eventsVp':      return s.eventsVp;
      case 'faunaBoardVp':  return s.faunaBoardVp;
      default:              return 0;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Number row
// ─────────────────────────────────────────────────────────────────────────────

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.category,
    required this.value,
    required this.onChanged,
  });

  final EarthCategory category;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: category.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(category.icon, color: category.iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Label + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (category.subtitle != null)
                  Text(
                    category.subtitle!,
                    style: tt.bodySmall
                        ?.copyWith(color: category.iconColor.withValues(alpha: 0.8)),
                  ),
              ],
            ),
          ),

          // Tooltip
          _TooltipButton(text: category.tooltip),
          const SizedBox(width: 4),

          // Number stepper
          _NumberStepper(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkbox row (first 4×4 complete)
// ─────────────────────────────────────────────────────────────────────────────

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.category,
    required this.checked,
    required this.bonusVp,
    required this.onChanged,
  });

  final EarthCategory category;
  final bool checked;
  final int bonusVp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: checked
            ? Colors.amber.withValues(alpha: 0.12)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: checked ? Colors.amber : cs.outlineVariant,
          width: checked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: category.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(category.icon, color: category.iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Label + bonus amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  checked ? '+$bonusVp VP earned!' : '+$bonusVp VP if first',
                  style: tt.bodySmall?.copyWith(
                    color: checked ? Colors.amber[800] : cs.outline,
                    fontWeight:
                        checked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          _TooltipButton(text: category.tooltip),
          const SizedBox(width: 4),

          // Switch
          Switch(
            value: checked,
            onChanged: onChanged,
            activeThumbColor: Colors.amber[700],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Number stepper  [-] [n] [+]
// ─────────────────────────────────────────────────────────────────────────────

class _NumberStepper extends StatefulWidget {
  const _NumberStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<_NumberStepper> {
  late TextEditingController _ctrl;
  late int _local;

  @override
  void initState() {
    super.initState();
    _local = widget.value;
    _ctrl = TextEditingController(text: '$_local');
  }

  @override
  void didUpdateWidget(_NumberStepper old) {
    super.didUpdateWidget(old);
    // Sync if value was changed externally (e.g. reset).
    if (widget.value != _local) {
      _local = widget.value;
      final sel = _ctrl.selection;
      _ctrl.text = '$_local';
      try {
        _ctrl.selection = sel;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _set(int v) {
    final clamped = v.clamp(0, 999);
    if (clamped == _local) return;
    setState(() => _local = clamped);
    _ctrl.text = '$clamped';
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus
        _StepBtn(
          icon: Icons.remove,
          onTap: () => _set(_local - 1),
          enabled: _local > 0,
        ),

        // Text input
        SizedBox(
          width: 52,
          child: TextField(
            controller: _ctrl,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              const _MaxValueFormatter(999),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: cs.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
            ),
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15),
            onChanged: (s) {
              final v = int.tryParse(s);
              if (v != null) {
                setState(() => _local = v.clamp(0, 999));
                widget.onChanged(_local);
              }
            },
            onTapOutside: (_) {
              // Normalise empty input to 0
              if (_ctrl.text.isEmpty) _set(0);
            },
          ),
        ),

        // Plus
        _StepBtn(
          icon: Icons.add,
          onTap: () => _set(_local + 1),
          enabled: _local < 999,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? cs.primary : cs.outline,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MaxValueFormatter extends TextInputFormatter {
  const _MaxValueFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final v = int.tryParse(newValue.text);
    if (v != null && v > max) return oldValue;
    return newValue;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TooltipButton extends StatelessWidget {
  const _TooltipButton({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: Icon(
        Icons.info_outline,
        size: 16,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group header
// ─────────────────────────────────────────────────────────────────────────────

class CategoryGroupHeader extends StatelessWidget {
  const CategoryGroupHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
