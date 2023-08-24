import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor/utils/util.dart';

import '../../utils/global.dart';
import '../brush_painter.dart';
import 'constants/constants.dart';

class TextEditor extends StatefulWidget {
  final TextBoxInput? textEditorStyle;

  const TextEditor({Key? key, this.textEditorStyle}) : super(key: key);

  @override
  createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  // textStyle values
  ValueNotifier<String> textNotifier = ValueNotifier<String>("");
  double fontSize = 32.0;
  Color currentColor = Colors.white;
  Color textBackgroundColor = Colors.transparent;
  TextAlign align = TextAlign.center;
  List<String> koreanFonts = googleFontsDetails.entries
      .where((entry) => (entry.value['subsets'] as String).contains('korean'))
      .map((entry) => entry.key)
      .toList();
  // local
  bool isFontBarVisible = true;

  int selectedFontIndex = 0;
  // for Navigator.pop
  bool isInitialBuild = true;
  bool isEditing = false;
  // for size and position
  final GlobalKey textBoxKey = GlobalKey();
  Rect get textBoxRect {
    final RenderBox? renderBox = textBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return Rect.zero;
    }
    log('${renderBox.size}\n${renderBox.globalToLocal(Offset.zero)}\t${renderBox.localToGlobal(Offset.zero)}\n${renderBox.globalToLocal(cardBoxRect.topLeft)}\t${renderBox.localToGlobal(cardBoxRect.topLeft)}');
    return renderBox.localToGlobal(Offset.zero) - cardBoxRect.topLeft & renderBox.size;
  }

  TextStyle get currentTextStyle => GoogleFonts.getFont(koreanFonts[selectedFontIndex]).copyWith(
        color: currentColor,
        fontSize: fontSize.toDouble(),
      );

  Size get textFieldSize => addSizes(
      _textSize,
      Size((inputDecorationTheme.contentPadding?.horizontal ?? 4) * 4,
          inputDecorationTheme.contentPadding?.vertical ?? 4));

  Size get _textSize => textSize(
      TextSpan(
        text: textNotifier.value,
        style: currentTextStyle,
      ),
      context);
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

  @override
  void initState() {
    super.initState();

    if (widget.textEditorStyle != null) {
      textNotifier.value = widget.textEditorStyle?.text ?? '';
      align = widget.textEditorStyle!.align;
      textBackgroundColor = widget.textEditorStyle!.backgroundColor;
      selectedFontIndex = getFontIndex();
      fontSize = widget.textEditorStyle!.style.fontSize ?? fontSize;
      currentColor = widget.textEditorStyle!.style.color ?? currentColor;
    }
  }

  TextBoxInput get input => TextBoxInput(
        text: textNotifier.value,
        align: align,
        style: currentTextStyle,
        backgroundColor: textBackgroundColor,
        size: textFieldSize,
      );
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData().copyWith(
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        inputDecorationTheme: inputDecorationTheme,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: ValueListenableBuilder(
            valueListenable: bottomInsetNotifier,
            builder: (context, bottomInset, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!isInitialBuild && bottomInset == 0.0 && !isEditing) {
                  Navigator.canPop(context) ? Navigator.pop(context) : null;
                } else {
                  isInitialBuild = false;
                }
              });

              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Align(
                        alignment: align == TextAlign.center
                            ? Alignment.center
                            : align == TextAlign.left
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                        child: ValueListenableBuilder<String>(
                            valueListenable: textNotifier,
                            builder: (context, text, child) {
                              return TextBox(
                                key: textBoxKey,
                                isReadOnly: false,
                                input: input,
                                onChanged: (value) => textNotifier.value = value,
                              );
                            }),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) {
                        log("onTapDown");
                        isEditing = true;
                      },
                      onTapUp: (_) {
                        log("onTapUp");
                        isEditing = false;
                      },
                      child: Container(
                        color: Colors.transparent,
                        width: objectBoxRect.width,
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
                              width: objectBoxRect.width,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (textNotifier.value.isEmpty) {
                                    Navigator.pop(context);
                                  } else {
                                    TextBoxInput result = input.copyWith(size: textBoxRect.size);
                                    Navigator.pop(context, (result, textBoxRect.topLeft));
                                  }
                                },
                                child: const Text("완료"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              );
            }),
      ),
    );
  }

  Widget _fontBar(BuildContext context) {
    return SingleChildScrollView(
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
            onTap: (color) async {
              isEditing = true;
              await showModalBottomSheet(
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
                          onColorChanged: (color) {
                            setState(() {
                              currentColor = color;
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
              isEditing = false;
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
      return widget.textEditorStyle!.style.fontFamily!.replaceAll(RegExp(r'_\w+'), '') == element;
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
}

class TextBoxInput {
  final String? text;
  final Size size;
  final TextStyle style;
  final TextAlign align;
  final Color backgroundColor;
  TextBoxInput({
    required this.text,
    required this.align,
    required this.style,
    required this.backgroundColor,
    required this.size,
  });

  TextBoxInput copyWith({
    String? text,
    TextAlign? align,
    TextStyle? style,
    Color? backgroundColor,
    Size? size,
  }) {
    return TextBoxInput(
      text: text ?? this.text,
      align: align ?? this.align,
      style: style ?? this.style,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      size: size ?? this.size,
    );
  }
}

class TextBox extends StatelessWidget {
  final bool isReadOnly;
  final ValueChanged<String>? onChanged;
  final TextBoxInput input;
  const TextBox({
    Key? key,
    required this.isReadOnly,
    this.onChanged,
    required this.input,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: input.size.width,
      margin: inputDecorationTheme.contentPadding,
      decoration: BoxDecoration(
        color: input.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextFormField(
        readOnly: isReadOnly,
        enabled: !isReadOnly,
        initialValue: input.text,
        textAlign: input.align,
        style: input.style,
        onChanged: onChanged,
        //
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.multiline,
        enableSuggestions: false,
        autocorrect: false,
        maxLines: null,
        autofocus: true,
      ),
    );
  }
}
