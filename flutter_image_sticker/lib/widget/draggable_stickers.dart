import 'package:flutter/material.dart';
import 'package:flutter_image_sticker/sticker.dart';

class DraggableStickers extends StatefulWidget {
  //List of stickers (elements)
  final List<Sticker>? stickerList;
  final String backgroundImage;

  // ignore: use_key_in_widget_constructors
  const DraggableStickers({this.stickerList, required this.backgroundImage});
  @override
  State<DraggableStickers> createState() => _DraggableStickersState();
}

Key? selectedAssetId;

class _DraggableStickersState extends State<DraggableStickers> {
  // initial scale of sticker
  final _initialStickerScale = 5.0;

  List<Sticker> stickers = [];
  @override
  void initState() {
    setState(() {
      stickers = widget.stickerList ?? [];
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(widget.backgroundImage, fit: BoxFit.cover),
          // Image.network(widget.backgroundImage, fit: BoxFit.cover),
          Positioned.fill(
            child: GestureDetector(
              key: const Key('stickersView_background_gestureDetector'),
              onTap: () {},
            ),
          ),
          for (final sticker in stickers)

            // Main widget that handles all features like rotate, resize, edit, delete, layer update etc.
            DraggableResizable(
              key: Key('stickerPage_${sticker.key}_draggableResizable_asset'),
              canTransform: selectedAssetId == sticker.key ? true : false

              //  true
              /*sticker.id == state.selectedAssetId*/,
              onUpdate: (update) => {},

              // To update the layer (manage position of widget in stack)
              onLayerTapped: () {},

              // To edit (Not implemented yet)
              onEdit: () {},

              // To Delete the sticker
              onDelete: () async {
                {
                  stickers.remove(sticker);
                  setState(() {});
                }
              },

              // Size of the sticker
              size: sticker.isText == true
                  ? Size(64 * _initialStickerScale / 3,
                      64 * _initialStickerScale / 3)
                  : Size(64 * _initialStickerScale, 64 * _initialStickerScale),

              // Constraints of the sticker
              constraints: sticker.isText == true
                  ? BoxConstraints.tight(
                      Size(
                        64 * _initialStickerScale / 3,
                        64 * _initialStickerScale / 3,
                      ),
                    )
                  : BoxConstraints.tight(
                      Size(
                        64 * _initialStickerScale,
                        64 * _initialStickerScale,
                      ),
                    ),

              // Child widget in which sticker is passed
              child: GestureDetector(
                onTapDown: (TapDownDetails details) {
                  selectedAssetId = sticker.key;
                  var listLength = stickers.length;
                  var index = stickers.indexOf(sticker);
                  if (index != listLength) {
                    stickers.remove(sticker);
                    stickers.add(sticker);
                  }

                  setState(() {});
                },
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: sticker.isText == true
                      ? FittedBox(child: sticker)
                      : sticker,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
