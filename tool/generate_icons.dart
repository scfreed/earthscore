// dart run tool/generate_icons.dart
//
// Generates two PNG files used by flutter_launcher_icons:
//   assets/icon/app_icon.png        — full icon (1024×1024, opaque bg)
//   assets/icon/app_icon_fg.png     — adaptive foreground (1024×1024, transparent bg)
//
// Uses dart:ui (available via `dart run` in a Flutter project).

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<void> main() async {
  await _saveIcon(
    outPath: 'assets/icon/app_icon.png',
    withBackground: true,
  );
  print('  ✓ assets/icon/app_icon.png');

  await _saveIcon(
    outPath: 'assets/icon/app_icon_fg.png',
    withBackground: false,
  );
  print('  ✓ assets/icon/app_icon_fg.png');
}

Future<void> _saveIcon({
  required String outPath,
  required bool withBackground,
}) async {
  const size = 1024.0;

  final recorder = ui.PictureRecorder();
  final canvas   = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

  _drawIcon(canvas, size, withBackground: withBackground);

  final picture = recorder.endRecording();
  final image   = await picture.toImage(size.toInt(), size.toInt());
  final bytes   = await image.toByteData(format: ui.ImageByteFormat.png);

  if (bytes == null) throw StateError('Failed to encode PNG');
  final data = bytes.buffer.asUint8List();

  File(outPath).writeAsBytesSync(data);
}

void _drawIcon(ui.Canvas canvas, double size, {required bool withBackground}) {
  final s = size;

  // ── Background ────────────────────────────────────────────────────────────
  if (withBackground) {
    final bgPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(s * 0.45, s * 0.42),
        s * 0.65,
        [const ui.Color(0xFF3A7230), const ui.Color(0xFF1C3D15)],
        [0.0, 1.0],
      );
    final rr = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, s, s),
      ui.Radius.circular(s * 0.22),
    );
    canvas.drawRRect(rr, bgPaint);
  }

  // ── Leaf shape ────────────────────────────────────────────────────────────
  final cx = s * 0.50;
  final cy = s * 0.50;

  final leafPath = ui.Path();
  // Tip at top-center, base at bottom
  leafPath.moveTo(cx, cy - s * 0.35);              // apex
  leafPath.cubicTo(
    cx + s * 0.30, cy - s * 0.20,                 // ctrl1
    cx + s * 0.32, cy + s * 0.20,                 // ctrl2
    cx,            cy + s * 0.36,                 // base
  );
  leafPath.cubicTo(
    cx - s * 0.32, cy + s * 0.20,
    cx - s * 0.30, cy - s * 0.20,
    cx,            cy - s * 0.35,
  );
  leafPath.close();

  // Fill with a light-to-dark green gradient
  final leafPaint = ui.Paint()
    ..shader = ui.Gradient.linear(
      ui.Offset(cx, cy - s * 0.35),
      ui.Offset(cx, cy + s * 0.36),
      [const ui.Color(0xFF7EC850), const ui.Color(0xFF3A8028)],
      [0.0, 1.0],
    );
  canvas.drawPath(leafPath, leafPaint);

  // Leaf outline
  final outlinePaint = ui.Paint()
    ..color = const ui.Color(0xFF2A6020)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = s * 0.012;
  canvas.drawPath(leafPath, outlinePaint);

  // ── Midrib (centre vein) ──────────────────────────────────────────────────
  final veinPaint = ui.Paint()
    ..color = const ui.Color(0xFF2A6020)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = s * 0.018
    ..strokeCap = ui.StrokeCap.round;

  canvas.drawLine(
    ui.Offset(cx, cy - s * 0.30),
    ui.Offset(cx, cy + s * 0.30),
    veinPaint,
  );

  // ── Lateral veins ─────────────────────────────────────────────────────────
  final thinVein = ui.Paint()
    ..color = const ui.Color(0xFF2A6020)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = s * 0.009
    ..strokeCap = ui.StrokeCap.round;

  final veinData = [
    // [startFracY, endFracX, endFracY]  (right side then mirrored)
    [-0.12,  0.22, -0.07],
    [ 0.03,  0.25,  0.08],
    [ 0.15,  0.22,  0.20],
    [ 0.25,  0.17,  0.30],
  ];

  for (final v in veinData) {
    final sy2 = cy + s * v[0];
    final ex  = cx + s * v[1];
    final ey  = cy + s * v[2];
    canvas.drawLine(ui.Offset(cx, sy2), ui.Offset(ex, ey), thinVein);
    canvas.drawLine(ui.Offset(cx, sy2), ui.Offset(cx * 2 - ex, ey), thinVein);
  }

  // ── Stem ─────────────────────────────────────────────────────────────────
  final stemPaint = ui.Paint()
    ..color = const ui.Color(0xFF2A6020)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = s * 0.022
    ..strokeCap = ui.StrokeCap.round;

  canvas.drawLine(
    ui.Offset(cx, cy + s * 0.30),
    ui.Offset(cx - s * 0.06, cy + s * 0.42),
    stemPaint,
  );
}
