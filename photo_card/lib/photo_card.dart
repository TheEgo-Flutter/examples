import 'dart:async';
import 'dart:developer';

import 'package:du_icons/du_icons.dart';
import 'package:flutter/foundation.dart';
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
  final List<LayerItem> tempSavedLayers;
  final AspectRatioEnum aspectRatio;

  late final ImageEditorType _type;
  late final Widget _widget;

  PhotoCard({
    super.key,
    this.tempSavedLayers = const [],
    this.aspectRatio = AspectRatioEnum.photoCard,
    Widget completedButton = const Text('Complete'),
    required List<Uint8List> stickers,
    required List<ImageProvider> backgrounds,
    required List<ImageProvider> frames,
    required List<String> fonts,
    Function(List<LayerItem>)? onReturnLayers,
    AsyncValueGetter<bool>? onDialog,
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
      onDialog: onDialog,
    );
  }

  PhotoCard.view({
    super.key,
    required this.tempSavedLayers,
    this.aspectRatio = AspectRatioEnum.photoCard,
  }) {
    _type = ImageEditorType.view;
    _widget = _PhotoCard(
      aspectRatio: aspectRatio,
      tempSavedLayers: tempSavedLayers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _widget;
  }
}
