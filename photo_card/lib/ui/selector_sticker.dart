import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StickerImageProvider {
  final Key? key;
  final ImageProvider image;
  final ImageProvider? animation; // if animation is not null, it will be used as a sticker

  const StickerImageProvider({this.key, required this.image, this.animation});

  ImageProvider get thumbnail {
    return image;
  }

  ImageProvider get sticker {
    return animation ?? image;
  }
}

class StickerSelector extends StatelessWidget {
  const StickerSelector({
    Key? key,
    required this.items,
    required this.onSelected,
  }) : super(key: key);

  final List<StickerImageProvider> items;
  final ValueChanged<ImageProvider?> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: false,
      physics: const ClampingScrollPhysics(),
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        StickerImageProvider item = items[index];
        return GestureDetector(
          onTap: () => onSelected(item.sticker),
          child: Image(
            image: item.thumbnail,
            fit: BoxFit.contain,
          ),
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
