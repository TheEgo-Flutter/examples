part of 'photo_card.dart';

class _PhotoCard extends StatefulWidget {
  final List<LayerItem> tempSavedLayers;
  final Size size;

  const _PhotoCard({required this.tempSavedLayers, required this.size});

  @override
  State<_PhotoCard> createState() => _PhotoCardViewerState();
}

class _PhotoCardViewerState extends State<_PhotoCard> {
  LayerManager layerManager = LayerManager();
  @override
  void initState() {
    layerManager.loadLayers(widget.tempSavedLayers);
    layerManager.newKeyLayers();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: ClipPath(
        clipper: CardBoxClip(aspectRatio: AspectRatioEnum.photoCard),
        child: Stack(
          children: [
            ...layerManager.layers.map((layer) {
              log(layer.rect.topLeft.toString());
              return Positioned(
                top: layer.rect.topLeft.dy,
                left: layer.rect.topLeft.dx,
                child: Transform.rotate(
                  angle: layer.angle,
                  child: buildChild(layer),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildChild(LayerItem layerItem) {
    try {
      switch (layerItem.type) {
        case TextType():
          layerItem.object as TextBoxInput;

          return TextBox(
            isReadOnly: true,
            input: layerItem.object,
          );

        case DrawingType():
          return Image.memory(
            layerItem.object as Uint8List,
            fit: BoxFit.fill,
            width: layerItem.rect.size.width,
            height: layerItem.rect.size.height,
          );
        case BackgroundType():
          switch (layerItem.type.background) {
            case Background.gallery:
              return SizedBox(
                height: layerItem.rect.size.height,
                width: layerItem.rect.size.width,
                child: layerItem.object,
              );
            case Background.image:
              return Image(
                image: layerItem.object as ImageProvider,
                fit: BoxFit.fill,
                width: layerItem.rect.size.width,
                height: layerItem.rect.size.height,
              );
            case Background.color:
              return Container(
                height: layerItem.rect.size.height,
                width: layerItem.rect.size.width,
                color: layerItem.object as Color,
              );
            default:
              return const SizedBox.shrink();
          }
        case FrameType():
          return Image(
            image: layerItem.object as ImageProvider,
            fit: BoxFit.fill,
            width: layerItem.rect.size.width,
            height: layerItem.rect.size.height,
          );

        case StickerType():
        default:
          return SizedBox(
            height: layerItem.rect.size.height,
            width: layerItem.rect.size.width,
            child: layerItem.object,
          );
      }
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
