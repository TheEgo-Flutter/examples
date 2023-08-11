import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ItemSelector extends StatelessWidget {
  ItemSelector.frame({
    super.key,
    required this.items,
    required this.onSelected,
  }) {
    widget = _FullSizeItemSelector(
      items: items,
      onSelected: onSelected,
      button: Icon(
        Icons.not_interested,
        color: Colors.grey[600],
      ),
    );
  }
  ItemSelector.background({
    super.key,
    required this.items,
    required this.onSelected,
  }) {
    widget = _FullSizeItemSelector(
      items: items,
      onSelected: onSelected,
      button: Icon(
        Icons.image_outlined,
        color: Colors.grey[600],
      ),
    );
  }
  ItemSelector.sticker({
    super.key,
    required this.items,
    required this.onSelected,
  }) {
    widget = _StickerSelector(
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

class _FullSizeItemSelector extends StatefulWidget {
  const _FullSizeItemSelector({
    required this.items,
    required this.onSelected,
    required this.button,
  });
  final Widget button;
  final List<dynamic> items;
  final ValueChanged<Widget?> onSelected;

  @override
  State<_FullSizeItemSelector> createState() => _FullSizeItemSelectorState();
}

class _FullSizeItemSelectorState extends State<_FullSizeItemSelector> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: widget.items.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          // 첫 아이템인 경우 버튼을 반환
          return _getFirstItemButton(widget.button, widget.onSelected);
        } else {
          int itemIndex = index - 1; // 실제 items의 인덱스
          var item = widget.items[itemIndex];

          Widget? child = _getItemChild(item);

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
            ),
            child: ClipRRect(
                //circle
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  color: Colors.grey[400],
                  child: GestureDetector(
                    onTap: () {
                      widget.onSelected(child);
                    },
                    child: child,
                  ),
                )),
          );
        }
      },
    );
  }

  _getFirstItemButton(Widget button, ValueChanged<Widget?> onSelected) {
    return GestureDetector(
      onTap: () => onSelected(null),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          color: Colors.grey[400],
          padding: const EdgeInsets.all(4.0),
          child: button,
        ),
      ),
    );
  }
}

class _StickerSelector extends StatelessWidget {
  const _StickerSelector({
    required this.items,
    required this.onSelected,
  });
  final List<dynamic> items;
  final ValueChanged<Widget?> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
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
              color: Colors.grey[400],
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
