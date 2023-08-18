import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor/utils/util.dart';

import '../../utils/global.dart';
import '../brush_painter.dart';
import 'constants/constants.dart';

const double textFieldSpacing = 10;

class TextEditor extends StatefulWidget {
  final TextEditorStyle? textEditorStyle;

  const TextEditor({Key? key, this.textEditorStyle}) : super(key: key);

  @override
  createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  bool isInitialBuild = true;
  double fontSize = 32.0;
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
  TextStyle get currentTextStyle => GoogleFonts.getFont(koreanFonts[selectedFontIndex]).copyWith(
        color: currentColor,
        fontSize: fontSize.toDouble(),
      );

  Size get textFieldSize => addSizes(_textSize, const Size((textFieldSpacing * 4), 10));

  Size get _textSize => textSize(
      TextSpan(
        text: textNotifier.value,
        style: currentTextStyle,
      ),
      context);
  @override
  void initState() {
    super.initState();
    if (widget.textEditorStyle != null) {
      textNotifier.value = widget.textEditorStyle!.text;
      align = widget.textEditorStyle!.textAlign;
      textBackgroundColor = widget.textEditorStyle!.backgroundColor;
      selectedFontIndex = getFontIndex();
      fontSize = widget.textEditorStyle!.textStyle.fontSize ?? fontSize;
      currentColor = widget.textEditorStyle!.textStyle.color ?? currentColor;
    }
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

  TextFormField _textField({bool readOnly = false}) => TextFormField(
        readOnly: readOnly,
        enabled: !readOnly,
        initialValue: textNotifier.value,
        textAlign: align,
        style: currentTextStyle,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(textFieldSpacing),
        ),
        onChanged: (value) => textNotifier.value = value,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.multiline,
        enableSuggestions: false,
        autocorrect: false,
        maxLines: null,
        autofocus: true,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: ValueListenableBuilder(
          valueListenable: bottomInsetNotifier,
          builder: (context, bottomInset, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!isInitialBuild && bottomInset == 0.0) {
                Navigator.pop(context);
              } else {
                isInitialBuild = false;
              }
            });

            return Stack(
              children: <Widget>[
                Transform.translate(
                    offset: Offset.zero,
                    child: LayoutBuilder(builder: (context, constraints) {
                      return _buildTextField();
                    })),
                Transform.translate(
                  offset: Offset(0, objectBoxRect.top - cardBoxRect.top - (bottomInset)),
                  child: SizedBox(
                    height: objectBoxRect.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
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
                          ],
                        ),
                        isFontBarVisible ? _fontBar(context) : _colorBar(context),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (textNotifier.value.isEmpty) {
                                Navigator.pop(context);
                              } else {
                                TextEditorStyle result = TextEditorStyle(
                                  text: textNotifier.value,
                                  textAlign: align,
                                  textStyle: currentTextStyle,
                                  backgroundColor: textBackgroundColor,
                                  fieldSize: textFieldSize,
                                );
                                Navigator.pop(context, result);
                              }
                            },
                            child: const Text("완료"),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }

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
              return Container(
                width: textFieldSize.width,
                margin: const EdgeInsets.all(textFieldSpacing),
                decoration: BoxDecoration(
                  color: textBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _textField(),
              );
            }),
      ),
    );
  }

  Widget _fontBar(BuildContext context) {
    return SizedBox(
      width: cardBoxRect.size.width,
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
      ],
    );
  }

  Size addSizes(Size size1, Size size2) {
    return Size(size1.width + size2.width, size1.height + size2.height);
  }

  /// element => Dongle
  /// fontFamily => Dongle_regular, Dongle_bold ...
  /// return element == fontFamily
  int getFontIndex() {
    int index = koreanFonts.indexWhere((element) {
      return widget.textEditorStyle!.textStyle.fontFamily!.replaceAll(RegExp(r'_\w+'), '') == element;
    });
    if (index < 0) {
      index = 0;
    }
    return index;
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
}

class TextEditorStyle {
  final String text;
  final TextAlign textAlign;
  final TextStyle textStyle;
  final Color backgroundColor;
  final Size fieldSize;
  TextEditorStyle({
    required this.text,
    required this.textAlign,
    required this.textStyle,
    required this.backgroundColor,
    required this.fieldSize,
  });

  TextEditorStyle copyWith({
    String? text,
    TextAlign? textAlign,
    TextStyle? textStyle,
    Color? backgroundColor,
    Size? fieldSize,
  }) {
    return TextEditorStyle(
      text: text ?? this.text,
      textAlign: textAlign ?? this.textAlign,
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fieldSize: fieldSize ?? this.fieldSize,
    );
  }
}

class TextEditedWidget extends StatefulWidget {
  const TextEditedWidget({super.key});

  @override
  State<TextEditedWidget> createState() => _TextEditedWidgetState();
}

class _TextEditedWidgetState extends State<TextEditedWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
