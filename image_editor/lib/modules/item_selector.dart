import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_editor/ui/label_switch.dart';
import 'package:image_editor/ui/rect.dart';
import 'package:image_editor/utils/global.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class ItemSelector extends StatelessWidget {
  ItemSelector.list({
    super.key,
    required this.items,
    required this.onSelected,
  }) {
    widget = _ListSelector(
      items: items,
      onSelected: onSelected,
      button: Icon(
        Icons.not_interested,
        color: Colors.grey[600],
      ),
    );
  }

  ItemSelector.grid({
    super.key,
    required this.items,
    required this.onSelected,
  }) {
    widget = _GridSelector(
      items: items,
      onSelected: onSelected,
    );
  }
  final List<dynamic> items;
  final ValueChanged<Widget?> onSelected;
  late final Widget? button;
  late final Widget widget;

  @override
  Widget build(BuildContext context) {
    return widget;
  }
}

class BackgroundItem {
  final BackgroundType type;
  final dynamic value;
  BackgroundItem.color(Color color)
      : type = BackgroundType.color,
        value = color;
  BackgroundItem.image(dynamic image)
      : type = BackgroundType.image,
        value = image;
}

enum BackgroundType {
  color('컬러'),
  image('배경');

  const BackgroundType(this.label);
  final String label;
}

class BackgroundSelector extends StatefulWidget {
  const BackgroundSelector({
    Key? key,
    required this.items,
    required this.onItemSelected,
    required this.onGallerySelected,
    required this.galleryButton,
  }) : super(key: key);

  final Widget galleryButton;
  final List<BackgroundItem> items;
  final ValueChanged<Widget?> onItemSelected;
  final ValueChanged<XFile?> onGallerySelected;

  @override
  State<BackgroundSelector> createState() => _BackgroundSelectorState();
}

class _BackgroundSelectorState extends State<BackgroundSelector> {
  final picker = ImagePicker();
  int toggleIndex = 0;
  int? selectedItemIndex;
  List<BackgroundItem> get currentItems => toggleIndex == 0
      ? widget.items.where((item) => item.type == BackgroundType.color).toList()
      : widget.items.where((item) => item.type == BackgroundType.image).toList();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double itemWidth = constraints.maxHeight * (ratio.ratio ?? 1) * (2 / 3);
        return Column(
          children: [
            Flexible(
              flex: 1,
              child: AnimatedToggle(
                values: BackgroundType.values.map((e) => e.label).toList(),
                onToggleCallback: (value) {
                  setState(() {
                    toggleIndex = value;
                  });
                },
                buttonColor: const Color(0xFFFFFFFF),
                backgroundColor: const Color(0xFF939393),
                textColor: const Color(0xFF000000),
              ),
            ),
            Expanded(
              flex: 3,
              child: ListView.separated(
                shrinkWrap: false,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: currentItems.length + (toggleIndex == 1 ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(
                  width: 8,
                ),
                itemBuilder: (BuildContext context, int index) {
                  Widget? item;
                  if (toggleIndex == 0) {
                    var backgroundItem = widget.items.where((e) => e.type == BackgroundType.color).toList()[index];
                    Widget? child = ColoredBox(color: backgroundItem.value as Color);
                    item = GestureDetector(
                      onTap: () {
                        widget.onItemSelected(child);
                        setState(() {
                          selectedItemIndex = index;
                        });
                      },
                      child: child,
                    );
                  } else {
                    if (index == 0) {
                      item = GestureDetector(
                        onTap: () async {
                          var image = await picker.pickImage(source: ImageSource.gallery);
                          widget.onGallerySelected(image);
                          setState(() {
                            selectedItemIndex = index;
                          });
                        },
                        child: ColoredBox(
                          color: const Color(0xff404040),
                          child: widget.galleryButton,
                        ),
                      );
                    } else {
                      int itemIndex = index - 1;
                      var backgroundItem =
                          widget.items.where((e) => e.type == BackgroundType.image).toList()[itemIndex];
                      Widget? child = _getItemChild(backgroundItem.value);

                      item = ColoredBox(
                        color: Colors.transparent,
                        child: GestureDetector(
                          onTap: () {
                            widget.onItemSelected(child);
                            setState(() {
                              selectedItemIndex = index;
                            });
                          },
                          child: child,
                        ),
                      );
                      return Transform.translate(
                        offset: index == selectedItemIndex ? Offset(0, -5) : Offset.zero,
                        child: SizedBox(
                          width: itemWidth,
                          child: ClipPath(
                            clipper: CardBoxClip(
                              aspectRatio: ratio,
                            ),
                            child: item,
                          ),
                        ),
                      );
                    }
                  }
                  return Transform.translate(
                    offset: index == selectedItemIndex ? Offset(0, -5) : Offset.zero,
                    child: SizedBox(
                      width: itemWidth,
                      child: ClipPath(
                        clipper: CardBoxClip(
                          aspectRatio: ratio,
                        ),
                        child: item,
                      ),
                    ),
                  );
                },
                padding: const EdgeInsets.all(8.0),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ListSelector extends StatefulWidget {
  const _ListSelector({
    required this.items,
    required this.onSelected,
    required this.button,
  });
  final Widget button;
  final List<dynamic> items;
  final ValueChanged<Widget?> onSelected;

  @override
  State<_ListSelector> createState() => _ListSelectorState();
}

class _ListSelectorState extends State<_ListSelector> {
  int? selectedItemIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double itemWidth = constraints.maxHeight * (ratio.ratio ?? 1) * (2 / 3);
      return Column(
        children: [
          Flexible(
            flex: 2,
            child: ListView.separated(
              shrinkWrap: false,
              physics: const ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: widget.items.length + 1,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(
                width: 8,
              ),
              itemBuilder: (BuildContext context, int index) {
                Widget? item;
                if (index == 0) {
                  item = _getFirstItemButton(widget.button, widget.onSelected);
                } else {
                  int itemIndex = index - 1;
                  var dataItem = widget.items[itemIndex];
                  Widget? child = _getItemChild(dataItem);

                  item = ColoredBox(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        widget.onSelected(child);
                        setState(() {
                          selectedItemIndex = index;
                        });
                      },
                      child: child,
                    ),
                  );
                }

                return Transform.translate(
                  offset: index == selectedItemIndex ? Offset(0, -5) : Offset.zero,
                  child: SizedBox(
                    width: itemWidth,
                    child: ClipPath(
                      clipper: CardBoxClip(aspectRatio: ratio),
                      child: item,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(flex: 1, child: Container())
        ],
      );
    });
  }

  _getFirstItemButton(Widget button, ValueChanged<Widget?> onSelected) {
    return GestureDetector(
      onTap: () {
        onSelected(null);
        setState(() {
          selectedItemIndex = 0;
        });
      },
      child: ColoredBox(
        color: const Color(0xff404040),
        child: button,
      ),
    );
  }
}

class _GridSelector extends StatelessWidget {
  const _GridSelector({
    required this.items,
    required this.onSelected,
  });
  final List<dynamic> items;
  final ValueChanged<Widget?> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: false,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.vertical,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        var item = items[index];
        Widget? child = _getItemChild(item);

        return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(4.0),
              child: GestureDetector(
                onTap: () => onSelected(child),
                child: child,
              ),
            ));
      },
    );
  }
}

_getItemChild(item) {
  Widget? child;
  if (item is Widget) {
    child = item;
  } else if (item is Uint8List) {
    try {
      json.decode(utf8.decode(item));

      child = LottieBuilder.memory(item);
    } catch (e) {
      child = Image.memory(item);
    }
  } else if (item is String) {
    if (item.contains('.json')) {
      child = Lottie.asset('assets/$item');
    } else if (item.startsWith('http')) {
      child = Image.network(item);
    } else {
      child = Image.asset('assets/$item');
    }
  }
  return child;
}
