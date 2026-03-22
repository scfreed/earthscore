import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../providers/players_provider.dart';

/// Shows the add/edit player bottom sheet.
/// Pass [existing] to edit; omit to add.
Future<void> showPlayerForm(
  BuildContext context, {
  Player? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PlayerFormSheet(existing: existing),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _PlayerFormSheet extends ConsumerStatefulWidget {
  const _PlayerFormSheet({this.existing});
  final Player? existing;

  @override
  ConsumerState<_PlayerFormSheet> createState() => _PlayerFormSheetState();
}

class _PlayerFormSheetState extends ConsumerState<_PlayerFormSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedColor;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _selectedColor =
        widget.existing?.colorHex ?? kPlayerColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(playersProvider.notifier);
    final name = _nameCtrl.text.trim();

    if (widget.existing == null) {
      notifier.addPlayer(name: name, colorHex: _selectedColor);
    } else {
      notifier.updatePlayer(
        widget.existing!.copyWith(name: name, colorHex: _selectedColor),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEdit = widget.existing != null;
    final players = ref.watch(playersProvider);

    // Bottom inset for keyboard
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              isEdit ? 'Edit Player' : 'Add Player',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ── Name field ────────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Player name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              maxLength: 20,
              validator: (v) {
                final val = v?.trim() ?? '';
                if (val.isEmpty) return 'Name is required';
                // Duplicate check (ignore self when editing)
                final dupe = players.any((p) =>
                    p.name.toLowerCase() == val.toLowerCase() &&
                    p.id != widget.existing?.id);
                if (dupe) return 'A player with this name already exists';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Colour picker ─────────────────────────────────────────────
            Text('Colour', style: tt.labelLarge),
            const SizedBox(height: 10),
            _ColorGrid(
              selected: _selectedColor,
              onTap: (hex) => setState(() => _selectedColor = hex),
            ),
            const SizedBox(height: 24),

            // ── Preview ───────────────────────────────────────────────────
            _AvatarPreview(name: _nameCtrl.text, colorHex: _selectedColor),
            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: Icon(isEdit ? Icons.check : Icons.person_add),
                    label: Text(isEdit ? 'Save Changes' : 'Add Player'),
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

// ─────────────────────────────────────────────────────────────────────────────

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.selected, required this.onTap});
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kPlayerColors.map((hex) {
        final color = Color(int.parse(hex, radix: 16));
        final isSelected = hex == selected;
        return GestureDetector(
          onTap: () => onTap(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : Border.all(color: Colors.transparent, width: 3),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: _fgFor(color),
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  static Color _fgFor(Color bg) =>
      bg.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;
}

// ─────────────────────────────────────────────────────────────────────────────

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.name, required this.colorHex});
  final String name;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = Color(int.parse(colorHex, radix: 16));

    String initials() {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty || parts.first.isEmpty) return '?';
      if (parts.length == 1) return parts[0][0].toUpperCase();
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    final fg = color.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Center(
              child: Text(
                initials(),
                style: TextStyle(
                  color: fg,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.trim().isEmpty ? 'Player Name' : name.trim(),
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text('Preview', style: tt.bodySmall?.copyWith(color: cs.outline)),
            ],
          ),
        ],
      ),
    );
  }
}
