import 'package:flutter/material.dart';

const primaryBlack = Color(0xFF121212);
const warmGold = Color(0xFFD9A752);
const darkGold = Color(0xFFC59243);
const warmBeige = Color(0xFFE5C495);
const secondaryBeige = Color(0xFFDEB887);
const surface = Color(0xFF0B0C0C);
const darkSurface = Color(0xFF181919);
const raisedSurface = Color(0xFF222323);
const cream = Color(0xFFF7F0E5);
const ink = cream;
const muted = Color(0xFFAAA59C);
const border = Color(0xFF303131);

class MenoWordmark extends StatelessWidget {
  const MenoWordmark({super.key, this.height = 36, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      onDark
          ? 'assets/brand/meno-wordmark-on-dark.png'
          : 'assets/brand/meno-wordmark.png',
      key: const Key('meno-wordmark'),
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.high,
    );
    return onDark
        ? ColorFiltered(
            colorFilter: const ColorFilter.mode(warmGold, BlendMode.srcIn),
            child: image,
          )
        : image;
  }
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
