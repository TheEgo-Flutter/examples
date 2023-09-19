import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class DiyResources {
  final List<ImageProvider> stickers;
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
    List<ImageProvider>? stickers,
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'stickers': stickers,
      'backgrounds': backgrounds,
      'frames': frames,
      'fonts': fonts,
    };
  }

  factory DiyResources.fromMap(Map<String, dynamic> map) {
    return DiyResources(
      stickers: List<ImageProvider>.from(map['stickers']),
      backgrounds: List<ImageProvider>.from(map['backgrounds']),
      frames: List<ImageProvider>.from(map['frames']),
      fonts: List<String>.from(map['fonts']),
    );
  }

  String toJson() => json.encode(toMap());

  factory DiyResources.fromJson(String source) => DiyResources.fromMap(json.decode(source));

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
