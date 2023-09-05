import 'dart:developer';

import 'package:du_icons/du_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor/utils/custom_color.g.dart';
import 'package:image_editor/widget/tool_bar.dart';
import 'package:image_editor/widget/vertical_slider.dart';

import '../../lib.dart';
import 'constants/constants.dart';

class TextEditor extends StatefulWidget {
  final TextBoxInput? textEditorStyle;

  const TextEditor({Key? key, this.textEditorStyle}) : super(key: key);

  @override
  createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  ValueNotifier<String> textNotifier = ValueNotifier<String>("");
  double fontSize = 24.0;
  Color currentColor = Colors.white;
  Color textBackgroundColor = Colors.transparent;
  TextAlign align = TextAlign.center;
  List<String> koreanFonts = googleFontsDetails.entries
      .where((entry) => (entry.value['subsets'] as String).contains('korean'))
      .map((entry) => entry.key)
      .toList();

  bool isFontBarVisible = true;

  int selectedFontIndex = 0;

  bool isInitialBuild = true;
  bool isEditing = false;

  final GlobalKey textBoxKey = GlobalKey();
  Rect get textBoxRect {
    final RenderBox? renderBox = textBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return Rect.zero;
    }
    log('${renderBox.size}\n${renderBox.globalToLocal(Offset.zero)}\t${renderBox.localToGlobal(Offset.zero)}\n${renderBox.globalToLocal(GlobalRect().cardRect.topLeft)}\t${renderBox.localToGlobal(GlobalRect().cardRect.topLeft)}');
    return renderBox.localToGlobal(Offset.zero) - GlobalRect().cardRect.topLeft & renderBox.size;
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
        return DUIcons.align_left;
      case TextAlign.right:
        return DUIcons.align_right;
      case TextAlign.center:
      default:
        return DUIcons.align_center;
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
  double fontMin = 12;
  double fontMax = 64;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: bottomInsetNotifier,
        builder: (context, bottomInset, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!isInitialBuild && bottomInset == 0.0 && !isEditing) {
              /*
                키보드 내려가면 뒤로가기 
              */
              Navigator.canPop(context) ? Navigator.pop(context) : null;
            } else {
              isInitialBuild = false;
            }
          });

          return TransformedWidget(
            themeData: ThemeData().copyWith(
              scaffoldBackgroundColor: Colors.black.withOpacity(0.2),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.black,
              ),
              inputDecorationTheme: inputDecorationTheme,
            ),
            top: GlobalToolBar(
              onConfirmPressed: () {
                if (textNotifier.value.isEmpty) {
                  Navigator.pop(context);
                } else {
                  TextBoxInput result = input.copyWith(size: textBoxRect.size);
                  Navigator.pop(context, (result, textBoxRect.topLeft));
                }
              },
            ),
            main: Expanded(
              child: SizedBox(
                width: GlobalRect().cardRect.width,
                // height: GlobalRect().cardRect.height,
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
            ),
            bottom: SizedBox(
              width: GlobalRect().objectRect.width,
              // color: Colors.black,
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
                  width: GlobalRect().objectRect.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(icon),
                            onPressed: _toggleAlign,
                            color: Colors.white,
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: isFontBarVisible ? rainbowColorButton() : const Icon(DUIcons.text),
                            onPressed: () {
                              setState(() {
                                isFontBarVisible = !isFontBarVisible;
                              });
                            },
                            color: Colors.white,
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                      isFontBarVisible
                          ? Container(margin: const EdgeInsets.symmetric(vertical: 8), child: _fontBar(context))
                          : ColorBar(
                              initialColor: currentColor,
                              onColorChanged: (value) {
                                setState(() {
                                  currentColor = value;
                                });
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
            left: VerticalSlider(
              min: fontMin,
              max: fontMax,
              value: fontSize,
              thumbColor: customColors.accent!,
              onChanged: (double v) => setState(() => fontSize = v),
            ),
          );
        });
  }

  Widget rainbowColorButton() => Container(
        height: IconTheme.of(context).size,
        width: IconTheme.of(context).size,
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
          ),
        ),
      );
/*
text effects
    IconButton(
      icon: const Icon(DUIcons.format_color_text_sharp),
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
 */
  Widget _fontBar(BuildContext context) {
    return Theme(
      data: ThemeData(canvasColor: Colors.transparent),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: koreanFonts.length,
          itemBuilder: (context, index) {
            String fontFamily = koreanFonts[index];
            bool isSelected = selectedFontIndex == index;
            return ChoiceChip(
              label: Text(
                'Aa',
                style: GoogleFonts.getFont(fontFamily).copyWith(color: isSelected ? Colors.purple[900] : Colors.white),
              ),
              shape: const CircleBorder(),
              selected: isSelected,
              selectedColor: Colors.white,
              backgroundColor: Colors.black.withOpacity(0.5),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedFontIndex = index;
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }

  Size addSizes(Size size1, Size size2) {
    return Size(size1.width + size2.width, size1.height + size2.height);
  }

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
