import 'dart:convert';
import 'dart:developer';
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

class BackgroundSelector extends StatefulWidget {
  const BackgroundSelector({
    super.key,
    required this.images,
    required this.colors,
    required this.onItemSelected,
    required this.onGallerySelected,
    required this.galleryButton,
  });
  final Widget galleryButton;
  final List<dynamic> images;
  final List<Color> colors;
  final ValueChanged<Widget?> onItemSelected;
  final ValueChanged<XFile?> onGallerySelected;

  @override
  State<BackgroundSelector> createState() => _BackgroundSelectorState();
}

class _BackgroundSelectorState extends State<BackgroundSelector> {
  final picker = ImagePicker();
  int toggleIndex = 0;
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
                values: const ['컬러', '배경'],
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
                itemCount: widget.images.length + 1,
                // itemExtent: itemWidth, // 아이템 간 간격
                separatorBuilder: (context, index) => const SizedBox(
                  width: 8,
                ),
                itemBuilder: (BuildContext context, int index) {
                  Widget? item;
                  if (toggleIndex == 0) {
                    Widget? child = ColoredBox(color: widget.colors[index]);
                    item = GestureDetector(
                      onTap: () {
                        widget.onItemSelected(child);
                      },
                      child: child,
                    );
                  } else {
                    if (index == 0) {
                      // 첫 아이템인 경우 버튼을 반환
                      item = GestureDetector(
                        onTap: () async {
                          var image = await picker.pickImage(source: ImageSource.gallery);
                          widget.onGallerySelected(image);
                        },
                        child: ColoredBox(
                          color: const Color(0xff404040),
                          child: widget.galleryButton,
                        ),
                      );
                    } else {
                      int itemIndex = index - 1; // 실제 items의 인덱스
                      var item = widget.images[itemIndex];

                      Widget? child = _getItemChild(item);
                      item = ColoredBox(
                        color: Colors.transparent,
                        child: GestureDetector(
                          onTap: () {
                            widget.onItemSelected(child);
                          },
                          child: child,
                        ),
                      );
                      return SizedBox(
                        width: itemWidth,
                        child: ClipPath(
                          clipper: CardBoxClip(aspectRatio: ratio),
                          child: item,
                        ),
                      );
                    }
                  }
                  return SizedBox(
                    width: itemWidth,
                    child: ClipPath(
                      clipper: CardBoxClip(
                        aspectRatio: ratio,
                      ),
                      child: item,
                    ),
                  );
                },
                padding: const EdgeInsets.all(8.0), // 모든 방향에 8 패딩 적용
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
                  // 첫 아이템인 경우 버튼을 반환
                  item = _getFirstItemButton(widget.button, widget.onSelected);
                } else {
                  int itemIndex = index - 1; // 실제 items의 인덱스
                  var item = widget.items[itemIndex];
                  Widget? child = _getItemChild(item);
                  log(child.toString());
                  item = ColoredBox(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        widget.onSelected(child);
                      },
                      child: child,
                    ),
                  );
                  return SizedBox(
                    width: itemWidth,
                    child: ClipPath(
                      clipper: CardBoxClip(aspectRatio: ratio),
                      child: item,
                    ),
                  );
                }
                return SizedBox(
                  width: itemWidth,
                  child: ClipPath(
                    clipper: CardBoxClip(aspectRatio: ratio),
                    child: item,
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
      onTap: () => onSelected(null),
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
      // 시도해 보기: JSON 파싱
      json.decode(utf8.decode(item));
      // 성공하면 Lottie로 처리
      child = LottieBuilder.memory(item);
    } catch (e) {
      // 실패하면 이미지로 처리
      child = Image.memory(item);
    }
  } else if (item is String) {
    if (item.contains('.json')) {
      // asset의 Lottie 처리
      child = Lottie.asset('assets/$item');
    } else if (item.startsWith('http')) {
      // 네트워크 이미지 처리
      child = Image.network(item);
    } else {
      // 로컬 asset 이미지 처리
      child = Image.asset('assets/$item');
    }
  }
  return child;
}
