library image_editor_plus;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hand_signature/signature.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/data/image_item.dart';
import 'package:image_editor/data/layer.dart';
import 'package:image_editor/layers/draggable_resizable.dart';
import 'package:image_editor/loading_screen.dart';
import 'package:image_editor/modules/all_emojies.dart';
import 'package:image_editor/modules/src/src.dart' as image_editor_src;
import 'package:image_editor/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';

import 'modules/colors_picker.dart';
import 'modules/text.dart';

late Size viewportSize;
double viewportRatio = 1;
ImageItem? baseLayer;
List<Layer> layers = [], undoLayers = [], removedLayers = [];
Map<String, String> _translations = {};
final GlobalKey editGlobalKey = GlobalKey();
Key? selectedAssetId;
final GlobalKey globalKey = GlobalKey();
String i18n(String sourceString) => _translations[sourceString.toLowerCase()] ?? sourceString;

class ImageEditor extends StatelessWidget {
  final Uint8List? image;
  final List? images;
  final List<String> stickers;
  final Directory? savePath;
  final int maxLength;
  final ImageEditorFeatures features;
  final List<AspectRatioOption> cropAvailableRatios;

  const ImageEditor({
    super.key,
    this.image,
    this.images,
    this.stickers = const [],
    this.savePath,
    this.maxLength = 99,
    this.features = const ImageEditorFeatures(
      pickFromGallery: true,
      captureFromCamera: true,
      crop: true,
      blur: true,
      brush: true,
      sticker: true,
      filters: true,
      flip: true,
      rotate: true,
      text: true,
    ),
    this.cropAvailableRatios = const [
      AspectRatioOption(title: 'Freeform'),
      AspectRatioOption(title: '1:1', ratio: 1),
      AspectRatioOption(title: '4:3', ratio: 4 / 3),
      AspectRatioOption(title: '5:4', ratio: 5 / 4),
      AspectRatioOption(title: '7:5', ratio: 7 / 5),
      AspectRatioOption(title: '16:9', ratio: 16 / 9),
    ],
  });
  static i18n(Map<String, String> translations) {
    translations.forEach((key, value) {
      _translations[key.toLowerCase()] = value;
    });
  }

  /// Set custom theme properties default is dark theme with white text
  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      background: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black87,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarTextStyle: TextStyle(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (images == null && image == null && !features.captureFromCamera && !features.pickFromGallery) {
      throw Exception('No image to work with, provide an image or allow the image picker.');
    }
    return SingleImageEditor(
      image: image,
      stickers: stickers,
      savePath: savePath,
      features: features,
      cropAvailableRatios: cropAvailableRatios,
    );
  }
}

class SingleImageEditor extends StatefulWidget {
  final Directory? savePath;
  final dynamic image;
  final List<String> stickers;
  final ImageEditorFeatures features;
  final List<AspectRatioOption> cropAvailableRatios;

  const SingleImageEditor({
    super.key,
    this.savePath,
    this.image,
    this.stickers = const [],
    this.features = const ImageEditorFeatures(
      pickFromGallery: true,
      captureFromCamera: true,
      crop: true,
      blur: true,
      brush: true,
      sticker: true,
      filters: true,
      flip: true,
      rotate: true,
      text: true,
    ),
    this.cropAvailableRatios = const [
      AspectRatioOption(title: 'Freeform'),
      AspectRatioOption(title: '1:1', ratio: 1),
      AspectRatioOption(title: '4:3', ratio: 4 / 3),
      AspectRatioOption(title: '5:4', ratio: 5 / 4),
      AspectRatioOption(title: '7:5', ratio: 7 / 5),
      AspectRatioOption(title: '16:9', ratio: 16 / 9),
    ],
  });

  @override
  createState() => _SingleImageEditorState();
}

class _SingleImageEditorState extends State<SingleImageEditor> {
  ImageItem currentImage = ImageItem();
  Offset offset1 = Offset.zero;
  Offset offset2 = Offset.zero;
  final scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void dispose() {
    layers.clear();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.image != null) {
      loadImage(widget.image!);
    }

    super.initState();
  }

  double flipValue = 0;
  int rotateValue = 0;

  double x = 0;
  double y = 0;
  double z = 0;

  double lastScaleFactor = 1, scaleFactor = 1;
  double widthRatio = 1, heightRatio = 1, pixelRatio = 1;

  resetTransformation() {
    scaleFactor = 1;
    x = 0;
    y = 0;
    setState(() {});
  }

  /// obtain image Uint8List by merging layers
  Future<Uint8List?> getMergedImage() async {
    if (layers.length == 1 && layers.first is BackgroundLayerData) {
      return (layers.first as BackgroundLayerData).file.image;
    }
    // else if (layers.length == 1 && layers.first is LayerData) {
    //   return (layers.first as LayerData).object;
    // }

    return screenshotController.capture(
      pixelRatio: pixelRatio,
    );
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;
    return Theme(
      data: ImageEditor.theme,
      child: Scaffold(
        key: scaffoldGlobalKey,
        backgroundColor: Colors.grey,
        appBar: appBar,
        body: Screenshot(
          controller: screenshotController,
          child: RepaintBoundary(
            key: editGlobalKey,
            child: baseLayer != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Image.memory(
                          baseLayer!.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          key: const Key('stickersView_background_gestureDetector'),
                          onTap: () {},
                        ),
                      ),
                      for (final layer in layers)
                        if (layer is LayerData)
                          DraggableResizable(
                            key: Key('stickerPage_${layer.key}_draggableResizable_asset'),
                            canTransform: selectedAssetId == layer.key ? true : false,
                            onDelete: () async {
                              layers.remove(layer);
                              setState(() {});
                            },
                            size: layer.size * layer.scale,
                            constraints: BoxConstraints.tight(layer.size * layer.scale),
                            child: GestureDetector(
                              onTapDown: (TapDownDetails details) {
                                selectedAssetId = layer.key;
                                var listLength = layers.length;
                                var index = layers.indexOf(layer);
                                if (index != listLength) {
                                  layers.remove(layer);
                                  layers.add(layer);
                                }
                                setState(() {});
                              },
                              child: SizedBox(
                                width: layer.size.width,
                                height: layer.size.height,
                                child: layer.object,
                              ),
                            ),
                          ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: bottomBar,
      ),
    );
  }

  AppBar get appBar {
    return AppBar(automaticallyImplyLeading: false, actions: [
      const BackButton(),
      SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        child: SingleChildScrollView(
          reverse: true,
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(Icons.undo, color: layers.length > 1 || removedLayers.isNotEmpty ? Colors.white : Colors.grey),
              onPressed: () {
                if (removedLayers.isNotEmpty) {
                  layers.add(removedLayers.removeLast());
                  setState(() {});
                  return;
                }

                if (layers.length <= 1) return; // do not remove image layer

                undoLayers.add(layers.removeLast());

                setState(() {});
              },
            ),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(Icons.redo, color: undoLayers.isNotEmpty ? Colors.white : Colors.grey),
              onPressed: () {
                if (undoLayers.isEmpty) return;

                layers.add(undoLayers.removeLast());

                setState(() {});
              },
            ),
            if (widget.features.pickFromGallery)
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: const Icon(Icons.photo),
                onPressed: () async {
                  var image = await picker.pickImage(source: ImageSource.gallery);

                  if (image == null) return;

                  loadImage(image);
                },
              ),
            if (widget.features.captureFromCamera)
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: const Icon(Icons.camera_alt),
                onPressed: () async {
                  var image = await picker.pickImage(source: ImageSource.camera);

                  if (image == null) return;

                  loadImage(image);
                },
              ),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.check),
              onPressed: () async {
                resetTransformation();
                setState(() {});

                LoadingScreen(scaffoldGlobalKey).show();

                var binaryIntList = await screenshotController.capture(pixelRatio: pixelRatio);

                LoadingScreen(scaffoldGlobalKey).hide();

                if (mounted) Navigator.pop(context, binaryIntList);
              },
            ),
          ]),
        ),
      ),
    ]);
  }

  final picker = ImagePicker();

  Future<void> loadImage(dynamic imageFile) async {
    await currentImage.load(imageFile);
    baseLayer = currentImage;
    layers.clear();
    setState(() {});
  }

  Widget get bottomBar => Container(
        height: const ButtonThemeData().height * 2,
        color: Colors.black87,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.features.brush)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit),
                      Text(
                        i18n('Brush'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    Uint8List? drawing = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageEditorDrawing(
                          image: currentImage,
                        ),
                      ),
                    );
                    if (drawing != null) {
                      undoLayers.clear();
                      removedLayers.clear();
                      layers.add(
                        LayerData(
                          key: UniqueKey(),
                          object: Image.memory(drawing),
                        ),
                      );
                      setState(() {});
                    }
                  },
                ),
              if (widget.features.text)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.text_fields),
                      Text(
                        i18n('Text'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    LayerData? layer = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TextEditorImage(),
                      ),
                    );
                    if (layer == null) return;
                    undoLayers.clear();
                    removedLayers.clear();
                    layers.add(layer);
                    setState(() {});
                  },
                ),
              if (widget.features.flip)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flip),
                      Text(
                        i18n('Flip'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    setState(() {
                      flipValue = flipValue == 0 ? math.pi : 0;
                    });
                  },
                ),
              if (widget.features.rotate)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rotate_left),
                      Text(
                        i18n('left'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    var t = currentImage.width;
                    currentImage.width = currentImage.height;
                    currentImage.height = t;
                    rotateValue--;
                    setState(() {});
                  },
                ),
              if (widget.features.rotate)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rotate_right),
                      Text(
                        i18n('right'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    var t = currentImage.width;
                    currentImage.width = currentImage.height;
                    currentImage.height = t;
                    rotateValue++;
                    setState(() {});
                  },
                ),
              if (widget.features.blur)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.blur_on),
                      Text(
                        i18n('Blur'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    var blurLayer = BackgroundBlurLayerData(
                      color: Colors.transparent,
                      radius: 0.0,
                      opacity: 0.0,
                    );
                    undoLayers.clear();
                    removedLayers.clear();
                    layers.add(blurLayer);
                    setState(() {});
                    showModalBottomSheet(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10)),
                      ),
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setS) {
                            return SingleChildScrollView(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius:
                                      BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10)),
                                ),
                                padding: const EdgeInsets.all(20),
                                height: 400,
                                child: Column(
                                  children: [
                                    Center(
                                        child: Text(
                                      i18n('Slider Filter Color').toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    )),
                                    const Divider(),
                                    const SizedBox(height: 20.0),
                                    Text(
                                      i18n('Slider Color'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                        child: BarColorPicker(
                                          width: 300,
                                          thumbColor: Colors.white,
                                          cornerRadius: 10,
                                          pickMode: PickMode.color,
                                          colorListener: (int value) {
                                            setS(() {
                                              setState(() {
                                                blurLayer.color = Color(value);
                                              });
                                            });
                                          },
                                        ),
                                      ),
                                      TextButton(
                                        child: Text(
                                          i18n('Reset'),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            setS(() {
                                              blurLayer.color = Colors.transparent;
                                            });
                                          });
                                        },
                                      )
                                    ]),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      i18n('Blur Radius'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Row(children: [
                                      Expanded(
                                        child: Slider(
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.grey,
                                          value: blurLayer.radius,
                                          min: 0.0,
                                          max: 10.0,
                                          onChanged: (v) {
                                            setS(() {
                                              setState(() {
                                                blurLayer.radius = v;
                                              });
                                            });
                                          },
                                        ),
                                      ),
                                      TextButton(
                                        child: Text(
                                          i18n('Reset'),
                                        ),
                                        onPressed: () {
                                          setS(() {
                                            setState(() {
                                              blurLayer.color = Colors.white;
                                            });
                                          });
                                        },
                                      )
                                    ]),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      i18n('Color Opacity'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10.0),
                                    Row(children: [
                                      Expanded(
                                        child: Slider(
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.grey,
                                          value: blurLayer.opacity,
                                          min: 0.00,
                                          max: 1.0,
                                          onChanged: (v) {
                                            setS(() {
                                              setState(() {
                                                blurLayer.opacity = v;
                                              });
                                            });
                                          },
                                        ),
                                      ),
                                      TextButton(
                                        child: Text(
                                          i18n('Reset'),
                                        ),
                                        onPressed: () {
                                          setS(() {
                                            setState(() {
                                              blurLayer.opacity = 0.0;
                                            });
                                          });
                                        },
                                      )
                                    ]),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              if (widget.features.filters)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo),
                      Text(
                        i18n('Filter'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    resetTransformation();
                    var mergedImage = await getMergedImage();
                    if (!mounted) return;
                    Uint8List? filterAppliedImage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageFilters(
                          image: mergedImage!,
                        ),
                      ),
                    );
                    if (filterAppliedImage == null) return;
                    removedLayers.clear();
                    undoLayers.clear();

                    baseLayer = ImageItem(filterAppliedImage);
                    await baseLayer?.status;
                    setState(() {});
                  },
                ),
              if (widget.features.sticker)
                ElevatedButton(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.face_5_outlined),
                      Text(
                        i18n('Sticker'),
                      )
                    ],
                  ),
                  onPressed: () async {
                    LayerData? layer = await showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.black,
                      builder: (BuildContext context) {
                        return Stickers(
                          stickers: widget.stickers,
                        );
                      },
                    );
                    if (layer == null) return;
                    undoLayers.clear();
                    removedLayers.clear();
                    layers.add(layer);
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      );
}

/// Return filter applied Uint8List image
class ImageFilters extends StatefulWidget {
  final Uint8List image;

  /// apply each filter to given image in background and cache it to improve UX
  final bool useCache;

  const ImageFilters({
    super.key,
    required this.image,
    this.useCache = true,
  });

  @override
  createState() => _ImageFiltersState();
}

class _ImageFiltersState extends State<ImageFilters> {
  late img.Image decodedImage;
  ColorFilterGenerator selectedFilter = PresetFilters.none;
  Uint8List resizedImage = Uint8List.fromList([]);
  double filterOpacity = 1;
  Uint8List filterAppliedImage = Uint8List.fromList([]);
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    // decodedImage = img.decodeImage(widget.image)!;
    // resizedImage = img.copyResize(decodedImage, height: 64).getBytes();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.check),
              onPressed: () async {
                var data = await screenshotController.capture();
                if (mounted) Navigator.pop(context, data);
              },
            ),
          ],
        ),
        body: Center(
          child: Screenshot(
            controller: screenshotController,
            child: Stack(
              children: [
                Image.memory(
                  widget.image,
                  fit: BoxFit.cover,
                ),
                FilterAppliedImage(
                  image: widget.image,
                  filter: selectedFilter,
                  fit: BoxFit.cover,
                  opacity: filterOpacity,
                  onProcess: (img) {
                    // print('processing done');
                    filterAppliedImage = img;
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: SizedBox(
            height: 160,
            child: Column(children: [
              SizedBox(
                height: 40,
                child: selectedFilter == PresetFilters.none
                    ? Container()
                    : selectedFilter.build(
                        Slider(
                          min: 0,
                          max: 1,
                          divisions: 100,
                          value: filterOpacity,
                          onChanged: (value) {
                            filterOpacity = value;
                            setState(() {});
                          },
                        ),
                      ),
              ),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    for (int i = 0; i < presetFiltersList.length; i++)
                      filterPreviewButton(
                        filter: presetFiltersList[i],
                        name: presetFiltersList[i].name,
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget filterPreviewButton({required filter, required String name}) {
    return GestureDetector(
      onTap: () {
        selectedFilter = filter;
        setState(() {});
      },
      child: Column(children: [
        Container(
          height: 64,
          width: 64,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: FilterAppliedImage(
              image: widget.image,
              filter: filter,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          i18n(name),
          style: const TextStyle(fontSize: 12),
        ),
      ]),
    );
  }
}

/// Short form of Image.memory wrapped in ColorFiltered
class FilterAppliedImage extends StatelessWidget {
  final Uint8List image;
  final ColorFilterGenerator filter;
  final BoxFit? fit;
  final Function(Uint8List)? onProcess;
  final double opacity;

  FilterAppliedImage({
    super.key,
    required this.image,
    required this.filter,
    this.fit,
    this.onProcess,
    this.opacity = 1,
  }) {
    // process filter in background
    if (onProcess != null) {
      // no filter supplied
      if (filter.filters.isEmpty) {
        onProcess!(image);
        return;
      }

      final image_editor_src.ImageEditorOption option = image_editor_src.ImageEditorOption();

      option.addOption(image_editor_src.ColorOption(matrix: filter.matrix));

      image_editor_src.ImageEditor.editImage(
        image: image,
        imageEditorOption: option,
      ).then((result) {
        if (result != null) {
          onProcess!(result);
        }
      }).catchError((err, stack) {
        // print(err);
        // print(stack);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (filter.filters.isEmpty) return Image.memory(image, fit: fit);

    return Opacity(
      opacity: opacity,
      child: filter.build(
        Image.memory(image, fit: fit),
      ),
    );
  }
}

/// Show image drawing surface over image
class ImageEditorDrawing extends StatefulWidget {
  final ImageItem image;

  const ImageEditorDrawing({
    super.key,
    required this.image,
  });

  @override
  State<ImageEditorDrawing> createState() => _ImageEditorDrawingState();
}

class _ImageEditorDrawingState extends State<ImageEditorDrawing> {
  Color pickerColor = Colors.white;
  Color currentColor = Colors.white;

  final control = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  List<CubicPath> undoList = [];
  bool skipNextEvent = false;

  List<Color> colorList = [
    Colors.black,
    Colors.white,
    Colors.blue,
    Colors.green,
    Colors.pink,
    Colors.purple,
    Colors.brown,
    Colors.indigo,
    Colors.indigo,
  ];

  void changeColor(Color color) {
    currentColor = color;
    setState(() {});
  }

  @override
  void initState() {
    control.addListener(() {
      if (control.hasActivePath) return;

      if (skipNextEvent) {
        skipNextEvent = false;
        return;
      }

      undoList = [];
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ImageEditor.theme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.clear),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(
                Icons.undo,
                color: control.paths.isNotEmpty ? Colors.white : Colors.white.withAlpha(80),
              ),
              onPressed: () {
                if (control.paths.isEmpty) return;
                skipNextEvent = true;
                undoList.add(control.paths.last);
                control.stepBack();
                setState(() {});
              },
            ),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(
                Icons.redo,
                color: undoList.isNotEmpty ? Colors.white : Colors.white.withAlpha(80),
              ),
              onPressed: () {
                if (undoList.isEmpty) return;

                control.paths.add(undoList.removeLast());
                setState(() {});
              },
            ),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (control.paths.isEmpty) return Navigator.pop(context);

                var data = await control.toImage(
                  color: currentColor,
                  height: widget.image.height,
                  width: widget.image.width,
                );

                if (!mounted) return;

                return Navigator.pop(context, data!.buffer.asUint8List());
              },
            ),
          ],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: currentColor == Colors.black ? Colors.white : Colors.black,
            image: DecorationImage(
              image: Image.memory(widget.image.image).image,
              fit: BoxFit.contain,
            ),
          ),
          child: HandSignature(
            control: control,
            color: currentColor,
            width: 1.0,
            maxWidth: 10.0,
            type: SignatureDrawType.shape,
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(blurRadius: 2),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                ColorButton(
                  color: Colors.yellow,
                  onTap: (color) {
                    showModalBottomSheet(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.black87,
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.only(top: 16),
                              child: HueRingPicker(
                                pickerColor: pickerColor,
                                onColorChanged: changeColor,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                for (int i = 0; i < colorList.length; i++)
                  ColorButton(
                    color: colorList[i],
                    onTap: (color) => changeColor(color),
                    isSelected: colorList[i] == currentColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button used in bottomNavigationBar in ImageEditorDrawing
class ColorButton extends StatelessWidget {
  final Color color;
  final Function onTap;
  final bool isSelected;

  const ColorButton({
    super.key,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap(color);
      },
      child: Container(
        height: 34,
        width: 34,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 23),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white54,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
