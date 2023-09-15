part of 'photo_card.dart';

class _PhotoCard extends StatefulWidget {
  final List<LayerItem> tempSavedLayers;
  final AspectRatioEnum aspectRatio;
  const _PhotoCard({required this.tempSavedLayers, required this.aspectRatio});

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
    return AspectRatio(
      aspectRatio: widget.aspectRatio.ratio ?? 1,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(CARD_RADIUS),
        child: Container(
          color: layerManager.backgroundLayer?.type.background == Background.color
              ? layerManager.backgroundLayer?.object as Color
              : Colors.transparent,
          child: Stack(
              children: layerManager.layers.map((layer) {
            return Transform(
              transform: Matrix4.identity()
                ..translate(layer.rect.topLeft.dx, layer.rect.topLeft.dy)
                ..rotateZ(layer.angle),
              child: buildChild(layer),
            );
          }).toList()),
        ),
      ),
    );
  }

  Widget buildChild(LayerItem layerItem) {
    try {
      switch (layerItem.type) {
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
              );
            case Background.color:
            default:
              return const SizedBox.shrink();
          }
        case DrawingType():
          return Image.memory(
            layerItem.object as Uint8List,
            fit: BoxFit.fill,
          );
        case FrameType():
          return Image(
            image: layerItem.object as ImageProvider,
            fit: BoxFit.fill,
          );
        case TextType():
          layerItem.object as TextBoxInput;
          return TextBox(
            isReadOnly: true,
            input: layerItem.object,
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
