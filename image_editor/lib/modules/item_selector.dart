import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_editor/ui/rect.dart';
import 'package:image_editor/utils/utils.dart';
import 'package:lottie/lottie.dart';

/*
  ColorBar(
                onColorChanged: (color) {
                  setState(() {
                    selectedColor = color;
                    widget.onItemSelected(ColoredBox(color: color));
                  });
                },
              ),
 */
class ImageSelector extends StatefulWidget {
  final Widget? firstItem;
  final List<ImageProvider> items;
  final ValueChanged<ImageProvider?> onItemSelected;

  const ImageSelector({
    Key? key,
    required this.items,
    this.firstItem,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  ImageSelectorState createState() => ImageSelectorState();
}

class ImageSelectorState extends State<ImageSelector> {
  int? selectedItemIndex;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: false,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.vertical,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 4.0,
        childAspectRatio: ratio.ratio ?? 1,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        Widget? item;
        if (index == 0 && widget.firstItem != null) {
          item = Container(
            decoration: BoxDecoration(
              color: const Color(0xff404040),
              borderRadius: BorderRadius.circular(4),
            ),
            child: widget.firstItem,
          );
        } else {
          int itemIndex = index - (widget.firstItem == null ? 0 : 1);
          ImageProvider child = widget.items[itemIndex];

          item = GestureDetector(
            onTap: () {
              widget.onItemSelected(child);
              setState(() {
                selectedItemIndex = index;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff404040),
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: child,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }

        return item;
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

class StickerSelector extends StatelessWidget {
  const StickerSelector({
    super.key,
    required this.items,
    required this.onSelected,
  });
  final List<Uint8List> items;
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
        return GestureDetector(
          onTap: () => onSelected(child),
          child: child,
        );
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
