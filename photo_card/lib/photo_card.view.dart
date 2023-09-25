part of 'photo_card.dart';

class PhotoCard extends StatefulWidget {
  final List<LayerItem> tempSavedLayers;
  final AspectRatioEnum aspectRatio;
  const PhotoCard({super.key, required this.tempSavedLayers, this.aspectRatio = AspectRatioEnum.photoCard});

  @override
  State<PhotoCard> createState() => _PhotoCardViewerState();
}

class _PhotoCardViewerState extends State<PhotoCard> {
  LayerManager layerManager = LayerManager();
  @override
  void initState() {
    layerManager.loadLayers(widget.tempSavedLayers);
    layerManager.newKeyLayers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      boxDecoration = await loadBackgroundColor();
      setState(() {});
    });

    super.initState();
  }

  BoxDecoration boxDecoration = const BoxDecoration(color: Colors.white);
  Future<BoxDecoration> loadBackgroundColor() async {
    if (layerManager.backgroundLayer?.type.background == Background.gallery) {
      var gradient = await loadImageColor(layerManager.backgroundLayer?.object as Image);
      if (gradient != null) {
        return BoxDecoration(gradient: gradient);
      } else {
        return const BoxDecoration(color: Colors.white);
      }
    } else if (layerManager.backgroundLayer?.type.background == Background.color) {
      return BoxDecoration(color: layerManager.backgroundLayer?.object as Color);
    } else {
      return const BoxDecoration(color: Colors.white);
    }
  }

  Future<LinearGradient?> loadImageColor(Image image) async {
    ColorScheme newScheme = await ColorScheme.fromImageProvider(provider: image.image);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomCenter,
      colors: [
        newScheme.primaryContainer,
        newScheme.primary,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio.ratio ?? 1,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(CARD_RADIUS),
        child: Container(
          decoration: boxDecoration,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(children: [
                ...layerManager.layers.map(
                  (layer) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..translate(layer.rect.topLeft.dx, layer.rect.topLeft.dy)
                        ..rotateZ(layer.angle),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: buildChild(layer),
                      ),
                    );
                  },
                ).toList(),
              ]);
            },
          ),
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
