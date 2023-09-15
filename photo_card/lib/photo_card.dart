import 'dart:async';
import 'dart:developer';

import 'package:du_icons/du_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'modules/modules.dart';
import 'ui/icon_button.dart';
import 'ui/ui.dart';
import 'utils/utils.dart';

part 'photo_card.edit.dart';
part 'photo_card.view.dart';

enum ImageEditorType {
  view,
  edit,
}

class PhotoCard extends StatelessWidget {
  late final ImageEditorType _type;
  late final Widget _widget;

  final List<Uint8List> stickers;
  final List<ImageProvider> backgrounds;
  final List<ImageProvider> frames;
  final AspectRatioEnum aspectRatio;
  final List<String> fonts;
  final List<LayerItem> tempSavedLayers;
  final Widget completedButton;
  final Function(List<LayerItem>)? onReturnLayers;
  PhotoCard({
    super.key,
    this.completedButton = const Text('Complete'),
    this.stickers = const [],
    this.backgrounds = const [],
    this.frames = const [],
    this.fonts = const [],
    this.aspectRatio = AspectRatioEnum.photoCard,
    this.tempSavedLayers = const [],
    this.onReturnLayers,
  }) {
    _type = ImageEditorType.edit;
    _widget = _PhotoEditor(
      stickers: stickers,
      backgrounds: backgrounds,
      frames: frames,
      fonts: fonts,
      aspectRatio: aspectRatio,
      tempSavedLayers: tempSavedLayers,
      completedButton: completedButton,
      onReturnLayers: onReturnLayers,
    );
  }

  PhotoCard.view({
    super.key,
    required Size size,
    required this.tempSavedLayers,
    this.completedButton = const SizedBox.shrink(),
    this.stickers = const [],
    this.backgrounds = const [],
    this.frames = const [],
    this.fonts = const [],
    this.aspectRatio = AspectRatioEnum.photoCard,
    this.onReturnLayers,
  }) {
    _type = ImageEditorType.view;
    _widget = _PhotoCard(
      size: size,
      tempSavedLayers: tempSavedLayers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _widget;
  }
}
