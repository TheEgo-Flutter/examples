import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:photo_card/lib.dart';

class DiyResources {
  final List<StickerImageProvider> stickers;
  final List<ImageProvider> backgrounds;
  final List<ImageProvider> frames;
  final List<String> fonts;

  DiyResources({
    required this.stickers,
    required this.backgrounds,
    required this.frames,
    required this.fonts,
  });

  DiyResources copyWith({
    List<StickerImageProvider>? stickers,
    List<ImageProvider>? backgrounds,
    List<ImageProvider>? frames,
    List<String>? fonts,
  }) {
    return DiyResources(
      stickers: stickers ?? this.stickers,
      backgrounds: backgrounds ?? this.backgrounds,
      frames: frames ?? this.frames,
      fonts: fonts ?? this.fonts,
    );
  }

  @override
  String toString() =>
      "DesignResources(stickers: $stickers, backgrounds: $backgrounds, frames: $frames, fonts: $fonts)";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiyResources &&
        listEquals(other.stickers, stickers) &&
        listEquals(other.backgrounds, backgrounds) &&
        listEquals(other.frames, frames) &&
        listEquals(other.fonts, fonts);
  }

  @override
  int get hashCode {
    return stickers.hashCode ^ backgrounds.hashCode ^ frames.hashCode ^ fonts.hashCode;
  }
}
