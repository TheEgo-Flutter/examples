part of 'photo_card.dart';

const double _cardAspectRatio = 300 / 464;

class PhotoCard extends ConsumerStatefulWidget {
  final List<LayerItem> tempSavedLayers;
  final PhotoCardController? controller;
  final double aspectRatio;
  const PhotoCard({
    super.key,
    required this.tempSavedLayers,
    this.controller,
    this.aspectRatio = _cardAspectRatio,
  });

  @override
  ConsumerState<PhotoCard> createState() => _PhotoCardViewerState();
}

class _PhotoCardViewerState extends ConsumerState<PhotoCard> {
  late final PhotoCardController controller;

  BoxDecoration boxDecoration = const BoxDecoration(color: Colors.white);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller = (widget.controller ?? PhotoCardController())..initial(ref.read(layerManagerNotifierProvider));
      ref.read(layerManagerNotifierProvider.notifier).loadLayers(widget.tempSavedLayers);
      ref.read(layerManagerNotifierProvider.notifier).newKeyLayers();

      boxDecoration = await loadBackgroundColor();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return FFmpegWidget(
      controller: controller.ffmpegController,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          decoration: boxDecoration,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(children: [
                ...ref.watch(layerManagerNotifierProvider).layers!.map(
                  (layer) {
                    Rect newRect = computeNewObjectRect(
                        backgroundOld: ref.watch(layerManagerNotifierProvider).layers!.first.rect,
                        objectOld: layer.rect,
                        backgroundNewSize: constraints.biggest);

                    LayerItem newItem = layer.copyWith(rect: newRect);

                    return Transform(
                      transform: Matrix4.identity()
                        ..translate(newRect.topLeft.dx, newRect.topLeft.dy)
                        ..rotateZ(layer.angle),
                      child: ChildLayerItem(
                        layerItem: newItem,
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

  Future<BoxDecoration> loadBackgroundColor() async {
    if (ref.watch(layerManagerNotifierProvider).backgroundLayer?.type.background == Background.gallery) {
      var gradient = await loadImageColor(ref.watch(layerManagerNotifierProvider).backgroundLayer?.object as Image);
      return BoxDecoration(gradient: gradient ?? const LinearGradient(colors: [Colors.white, Colors.white]));
    } else if (ref.watch(layerManagerNotifierProvider).backgroundLayer?.type.background == Background.color) {
      return BoxDecoration(color: ref.watch(layerManagerNotifierProvider).backgroundLayer?.object as Color);
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
}

class PhotoCardController {
  late FFMpegController ffmpegController;
  late final LayerManager layerManager;
  final List<GifController> controllers = [];

  PhotoCardController();
  void initial(LayerManager layerManager) {
    this.layerManager = layerManager;
    ffmpegController = FFMpegController();
    for (var element in layerManager.layers ?? []) {
      if (element.type is StickerType && element.object is GifView) {
        // ffmpegController.duration =
        //     ((element.object as GifView).fadeDuration! * (element.object as GifView).controller!.countFrames);
        (element.object as GifView).controller != null
            ? controllers.add((element.object as GifView).controller!)
            : null;
      }
    }
  }

  void play({GifStatus? status}) {
    if (status == null) {
      if (controllers.first.status == GifStatus.playing) {
        for (GifController controller in controllers) {
          controller.pause();
        }
        return;
      } else {
        for (GifController controller in controllers) {
          controller.play(initialFrame: 0);
        }
      }
    } else {
      if (status == GifStatus.playing) {
        for (GifController controller in controllers) {
          controller.pause();
          controller.play(initialFrame: 0);
        }
      } else {
        for (GifController controller in controllers) {
          controller.pause();
        }
      }
    }
  }

  Future<File?> encoding() async {
    Duration fadeDuration = const Duration(milliseconds: 200);
    int totalFrame = 0;
    for (var element in layerManager.layers ?? []) {
      if (element.type is StickerType && (element.object as GifView).fadeDuration != null) {
        fadeDuration = (element.object as GifView).fadeDuration!;
        totalFrame = controllers.first.countFrames;
        break;
      }
    }
    play(status: GifStatus.playing);

    return await ffmpegController.captureDurationToVideo(totalFrames: totalFrame, frameDelay: fadeDuration);
  }
}

Rect computeNewObjectRect({
  required Rect backgroundOld,
  required Rect objectOld,
  required Size backgroundNewSize,
}) {
  double xScale = backgroundNewSize.width / backgroundOld.width;
  double yScale = backgroundNewSize.height / backgroundOld.height;
  double objectNewWidth = objectOld.width * xScale;
  double objectNewHeight = objectOld.height * yScale;
  double objectNewLeft = objectOld.left * xScale;
  double objectNewTop = objectOld.top * yScale;
  return Rect.fromLTWH(objectNewLeft, objectNewTop, objectNewWidth, objectNewHeight);
}
