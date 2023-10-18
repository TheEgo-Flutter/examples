import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_card/lib.dart';

class ChildLayerItem extends StatelessWidget {
  final LayerItem layerItem;
  final Size? customSize;

  const ChildLayerItem({Key? key, required this.layerItem, this.customSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      Size targetSize = customSize ?? layerItem.rect.size;

      switch (layerItem.type) {
        case DrawingType():
          return Image.memory(
            layerItem.object as Uint8List,
            fit: BoxFit.fill,
            width: targetSize.width,
            height: targetSize.height,
          );
        case BackgroundType():
          switch (layerItem.type.background) {
            case Background.gallery:
              return SizedBox(
                height: targetSize.height,
                width: targetSize.width,
                child: layerItem.object,
              );
            case Background.image:
              return Image(
                image: layerItem.object as ImageProvider,
                fit: BoxFit.fill,
                width: targetSize.width,
                height: targetSize.height,
              );
            case Background.color:
              return Container(
                height: targetSize.height,
                width: targetSize.width,
                color: layerItem.object as Color,
              );
            default:
              return const SizedBox.shrink();
          }
        case FrameType():
          return Image(
            image: layerItem.object as ImageProvider,
            fit: BoxFit.fill,
            width: targetSize.width,
            height: targetSize.height,
          );
        case StickerType():
          return Image(
            width: targetSize.width,
            height: targetSize.height,
            image: layerItem.object as ImageProvider,
          );
        case TextType():
          return TextBox(
            isReadOnly: true,
            input: layerItem.object,
          );
        default:
          return const SizedBox.shrink();
      }
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
