import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor/image_editor.dart';
import 'package:image_editor/utils.dart';

import '../brush_painter.dart';
import 'constants/constants.dart';

class TextEditor extends StatefulWidget {
  final InlineSpan? inlineSpan;

  const TextEditor({Key? key, this.inlineSpan}) : super(key: key);

  @override
  createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  TextEditingController controller = TextEditingController();
  double slider = 32.0;
  Color currentColor = Colors.white;
  Color textBackgroundColor = Colors.transparent;
  List<String> koreanFonts = googleFontsDetails.entries
      .where((entry) => (entry.value['subsets'] as String).contains('korean'))
      .map((entry) => entry.key)
      .toList();
  ValueNotifier<String> textNotifier = ValueNotifier<String>("");
  bool isFontBarVisible = true;
  TextAlign align = TextAlign.center;
  int selectedFontIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.inlineSpan != null) {
      controller.text = widget.inlineSpan?.toPlainText() ?? '';

      if (textSpan.style != null) {
        selectedFontIndex = koreanFonts.indexOf(textSpan.style?.fontFamily ?? '');
        selectedFontIndex = selectedFontIndex != -1 ? selectedFontIndex : 0;
        slider = textSpan.style?.fontSize ?? 32.0;
        currentColor = textSpan.style?.color ?? Colors.white;
      }
    }

    controller.addListener(() => textNotifier.value = controller.text);
  }

  IconData get icon {
    switch (align) {
      case TextAlign.left:
        return Icons.align_horizontal_left;
      case TextAlign.right:
        return Icons.align_horizontal_right;
      case TextAlign.center:
      default:
        return Icons.align_horizontal_center;
    }
  }

  void _toggleAlign() {
    setState(() {
      switch (align) {
        case TextAlign.left:
          align = TextAlign.center;
          break;
        case TextAlign.right:
          align = TextAlign.left;
          break;
        case TextAlign.center:
        default:
          align = TextAlign.right;
          break;
      }
    });
  }

  void changeColor(Color color) {
    currentColor = color;
    setState(() {});
  }

  TextSpan get textSpan => TextSpan(
        text: controller.text,
        style: GoogleFonts.getFont(koreanFonts[selectedFontIndex]).copyWith(
          color: currentColor,
          fontSize: slider.toDouble(),
        ),
      );

  Align _buildTextField() {
    return Center(
      child: Align(
        alignment: align == TextAlign.center
            ? Alignment.center
            : align == TextAlign.left
                ? Alignment.centerLeft
                : Alignment.centerRight,
        child: ValueListenableBuilder<String>(
            valueListenable: textNotifier,
            builder: (context, text, child) {
              double textWidth = textSize(textSpan, context).width;
              const double spacing = 10;
              textWidth = textWidth + (spacing * 4);
              return Container(
                width: textWidth,
                margin: const EdgeInsets.all(spacing),
                decoration: BoxDecoration(
                  color: textBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: controller,
                  textAlign: align,
                  enableSuggestions: false,
                  autocorrect: false,
                  style: textSpan.style,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(spacing),
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  autofocus: true,
                ),
              );
            }),
      ),
    );
  }

  Row _buildAppBar() {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: _toggleAlign,
          color: Colors.white,
          padding: const EdgeInsets.all(15),
        ),
        IconButton(
          icon: isFontBarVisible ? const Icon(Icons.color_lens) : const Icon(Icons.text_fields),
          onPressed: () {
            setState(() {
              isFontBarVisible = !isFontBarVisible;
            });
          },
          color: Colors.white,
          padding: const EdgeInsets.all(15),
        ),
        IconButton(
          icon: const Icon(Icons.format_color_text_sharp),
          onPressed: () {
            setState(() {
              textBackgroundColor = textBackgroundColor == Colors.transparent
                  ? Colors.black45
                  : textBackgroundColor == Colors.black45
                      ? Colors.white54
                      : Colors.transparent;
            });
          },
          color: Colors.white,
          padding: const EdgeInsets.all(15),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            if (controller.text.isEmpty) {
              Navigator.pop(context);
            } else {
              Navigator.pop(context, textSpan);
            }
          },
          color: Colors.white,
          padding: const EdgeInsets.all(15),
        )
      ],
    );
  }

  Widget _fontBar(BuildContext context) {
    return SizedBox(
      width: cardSize.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: koreanFonts.asMap().entries.map((entry) {
            int index = entry.key;
            String fontFamily = entry.value;

            return ChoiceChip(
              label: Text(
                'Aa',
                style: GoogleFonts.getFont(fontFamily),
              ),
              shape: const CircleBorder(),
              selected: selectedFontIndex == index,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedFontIndex = index;
                    controller.text = controller.text;
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Row _colorBar(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: [
                  0.1,
                  0.4,
                  0.6,
                  0.9,
                ],
                colors: [
                  Colors.yellow,
                  Colors.red,
                  Colors.indigo,
                  Colors.teal,
                ],
              )),
          child: ColorButton(
            color: Colors.transparent,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            onTap: (color) {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    color: textBackgroundColor,
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.only(top: 16),
                        child: HueRingPicker(
                          pickerColor: currentColor,
                          onColorChanged: changeColor,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Slider(
          min: 8.0,
          max: 72.0,
          value: slider,
          onChanged: (value) {
            setState(() {
              slider = value;
            });
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: <Widget>[
              _buildTextField(),
              Transform.translate(
                offset: const Offset(0, 0),
                child: _buildAppBar(),
              ),
              Visibility(
                visible: MediaQuery.of(context).viewInsets.bottom == 0,
                child: Positioned(
                  bottom: 25,
                  left: 0,
                  child: isFontBarVisible ? _fontBar(context) : _colorBar(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
