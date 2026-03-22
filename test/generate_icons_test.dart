// flutter test test/generate_icons_test.dart
//
// Renders EarthScore app icons and writes them to assets/icon/.

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate app icons', () async {
    await _generate('assets/icon/app_icon.png',    withBg: true);
    await _generate('assets/icon/app_icon_fg.png', withBg: false);
    print('Icons written to assets/icon/');
  });
}

Future<void> _generate(String path, {required bool withBg}) async {
  const int sz = 1024;

  final recorder = ui.PictureRecorder();
  final canvas   = ui.Canvas(recorder,
      ui.Rect.fromLTWH(0, 0, sz.toDouble(), sz.toDouble()));

  _paint(canvas, sz.toDouble(), withBg: withBg);

  final picture = recorder.endRecording();
  final image   = await picture.toImage(sz, sz);
  final data    = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('PNG encoding failed');

  File(path).writeAsBytesSync(data.buffer.asUint8List());
}

void _paint(ui.Canvas c, double s, {required bool withBg}) {
  // ── Background ────────────────────────────────────────────────────────────
  if (withBg) {
    final p = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(s * 0.45, s * 0.42),
        s * 0.65,
        [const ui.Color(0xFF3A7230), const ui.Color(0xFF1C3D15)],
      );
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(0, 0, s, s),
        ui.Radius.circular(s * 0.22),
      ),
      p,
    );
  }

  final cx = s * 0.50;
  final cy = s * 0.50;

  // ── Leaf ──────────────────────────────────────────────────────────────────
  final leaf = ui.Path()
    ..moveTo(cx, cy - s * 0.35)
    ..cubicTo(
        cx + s * 0.30, cy - s * 0.20,
        cx + s * 0.32, cy + s * 0.20,
        cx,            cy + s * 0.36)
    ..cubicTo(
        cx - s * 0.32, cy + s * 0.20,
        cx - s * 0.30, cy - s * 0.20,
        cx,            cy - s * 0.35)
    ..close();

  c.drawPath(
    leaf,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(cx, cy - s * 0.35),
        ui.Offset(cx, cy + s * 0.36),
        [const ui.Color(0xFF7EC850), const ui.Color(0xFF3A8028)],
      ),
  );

  c.drawPath(
    leaf,
    ui.Paint()
      ..color = const ui.Color(0xFF2A6020)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = s * 0.012,
  );

  // ── Midrib ────────────────────────────────────────────────────────────────
  final midrib = ui.Paint()
    ..color = const ui.Color(0xFF2A6020)
    ..strokeWidth = s * 0.018
    ..strokeCap = ui.StrokeCap.round;
  c.drawLine(ui.Offset(cx, cy - s * 0.30), ui.Offset(cx, cy + s * 0.30), midrib);

  // ── Lateral veins ─────────────────────────────────────────────────────────
  final vein = ui.Paint()
    ..color = const ui.Color(0xFF2A6020)
    ..strokeWidth = s * 0.009
    ..strokeCap = ui.StrokeCap.round;

  for (final v in [
    [-0.12,  0.22, -0.07],
    [ 0.03,  0.25,  0.08],
    [ 0.15,  0.22,  0.20],
    [ 0.25,  0.17,  0.30],
  ]) {
    final sy = cy + s * v[0];
    final ex = cx + s * v[1];
    final ey = cy + s * v[2];
    c.drawLine(ui.Offset(cx, sy), ui.Offset(ex, ey), vein);
    c.drawLine(ui.Offset(cx, sy), ui.Offset(cx * 2 - ex, ey), vein);
  }

  // ── Stem ─────────────────────────────────────────────────────────────────
  c.drawLine(
    ui.Offset(cx, cy + s * 0.30),
    ui.Offset(cx - s * 0.06, cy + s * 0.42),
    ui.Paint()
      ..color = const ui.Color(0xFF2A6020)
      ..strokeWidth = s * 0.022
      ..strokeCap = ui.StrokeCap.round,
  );
}
