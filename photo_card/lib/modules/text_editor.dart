import 'package:du_icons/du_icons.dart';
import 'package:flutter/material.dart';
import 'package:photo_card/ui/ui.dart';

import '../utils/global.dart';
import '../utils/global.rect.dart';
import '../utils/util.dart';

List<String> fontFamilies = [];

class TextEditor extends StatefulWidget {
  final TextBoxInput? textEditorStyle;

  const TextEditor({Key? key, this.textEditorStyle}) : super(key: key);

  @override
  createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  ValueNotifier<String> textNotifier = ValueNotifier<String>("");
  double fontSize = 24.0;
  Color currentColor = Colors.black;
  Color textBackgroundColor = Colors.transparent;
  TextAlign align = TextAlign.center;

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

    InlineSpan? span = TextSpan(text: input.text, style: input.style);
    Size size = textSize(span, context, maxWidth: GlobalRect().cardRect.width);

    Rect rect = Offset((GlobalRect().cardRect.right - GlobalRect().cardRect.left) / 2 - (size.width + 30) / 2,
            renderBox.localToGlobal(Offset.zero).dy - GlobalRect().cardRect.topLeft.dy) &
        Size(size.width + 30, size.height + 30);

    return rect;
  }

  TextStyle get currentTextStyle => TextStyle(
        color: currentColor,
        fontSize: fontSize.toDouble(),
        fontFamily: _fontFamily,
        fontWeight: _fontWeight,
        letterSpacing: 2.0,
      );
  String get _fontFamily {
    return fontFamilies[selectedFontIndex];
  }

  FontWeight get _fontWeight {
    return fontFamilies[selectedFontIndex].toLowerCase().contains('bold') ? FontWeight.bold : FontWeight.normal;
  }

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
                Navigator.canPop(context) ? Navigator.pop(context) : null;
              */
            } else {
              isInitialBuild = false;
            }
          });

          return TransformedWidget(
            resizeToAvoidBottomInset: true,
            themeData: ThemeData().copyWith(
              scaffoldBackgroundColor: Colors.black.withOpacity(0.2),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.black,
              ),
            ),
            top: GlobalToolBar(
              onConfirmPressed: () {
                if (textNotifier.value.trim().isEmpty) {
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context, (input, textBoxRect));
                }
              },
            ),
            center: Expanded(
              child: SizedBox(
                width: GlobalRect().cardRect.width,
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
            bottom: Expanded(
              child: Container(
                color: Colors.transparent,
                width: GlobalRect().objectRect.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
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
                            value: currentColor,
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
            left: VerticalSlider(
              min: fontMin,
              max: fontMax,
              value: fontSize,
              thumbColor: accent,
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

  Widget _fontBar(BuildContext context) {
    if (fontFamilies.isEmpty) {
      return const SizedBox.shrink();
    }
    return Theme(
      data: ThemeData(canvasColor: Colors.transparent),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: fontFamilies.length,
          itemBuilder: (context, index) {
            String fontFamily = fontFamilies[index];
            bool isSelected = selectedFontIndex == index;
            return ChoiceChip(
              label: Text('가',
                  style: TextStyle(
                    color: isSelected ? Colors.purple[900] : Colors.white,
                    fontFamily: fontFamily,
                    fontSize: (ChipTheme.of(context).labelStyle?.fontSize ?? 12) * 0.8,
                  )),
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
    int index = fontFamilies.indexWhere((element) {
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
  final TextStyle style;
  final TextAlign align;
  final Color backgroundColor;
  TextBoxInput({
    required this.text,
    required this.align,
    required this.style,
    required this.backgroundColor,
  });

  TextBoxInput copyWith({
    String? text,
    TextAlign? align,
    TextStyle? style,
    Color? backgroundColor,
  }) {
    return TextBoxInput(
      text: text ?? this.text,
      align: align ?? this.align,
      style: style ?? this.style,
      backgroundColor: backgroundColor ?? this.backgroundColor,
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
    return Theme(
      data: ThemeData(
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
        ),
      ),
      child: TextFormField(
        readOnly: isReadOnly,
        enabled: !isReadOnly,
        initialValue: input.text,
        textAlign: input.align,
        style: input.style.copyWith(fontSize: input.style.fontSize),
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
