import 'package:flutter/material.dart';

const primaryBlack = Color(0xFF121212);
const warmGold = Color(0xFFD9A752);
const darkGold = Color(0xFFC59243);
const warmBeige = Color(0xFFE5C495);
const secondaryBeige = Color(0xFFDEB887);
const surface = Color(0xFFFAF9F6);
const ink = primaryBlack;
const muted = Color(0xFF68635C);
const border = Color(0xFFE8E3DA);

class MenoWordmark extends StatelessWidget {
  const MenoWordmark({super.key, this.height = 36});

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/meno-wordmark.png',
        key: const Key('meno-wordmark'),
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.high,
      );
}

class MenoMark extends StatelessWidget {
  const MenoMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/meno-mark.png',
        key: const Key('meno-mark'),
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
      );
}
