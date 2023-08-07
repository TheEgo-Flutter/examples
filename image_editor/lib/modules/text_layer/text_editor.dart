import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../brush_painter.dart';

class TextEditor extends StatefulWidget {
  const TextEditor({super.key});

  @override
  createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> with WidgetsBindingObserver {
  TextEditingController controller = TextEditingController();

  double slider = 32.0;
  Color pickerColor = Colors.white;
  Color currentColor = Colors.white;
  bool isKeyboardActive = false;
  double keyboardHeight = 0.0;
  TextAlign align = TextAlign.center;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final keyboardBottomInset = MediaQuery.of(context).viewInsets.bottom;
    isKeyboardActive = keyboardBottomInset > 0;
    keyboardHeight = keyboardBottomInset;
    setState(() {});
  }

  void changeColor(Color color) {
    currentColor = color;
    setState(() {});
  }

  List<Color> colorList = [
    Colors.black,
    Colors.white,
    Colors.blue,
    Colors.green,
    Colors.pink,
    Colors.purple,
    Colors.brown,
    Colors.indigo,
    Colors.indigo,
  ];
  double get availableHeight {
    double appBarHeight = 56.0; // 앱바의 기본 높이
    double extraHeight = 25.0; // 추가 UI 요소 높이
    return MediaQuery.of(context).size.height - appBarHeight - keyboardHeight - extraHeight;
  }

  int get maxLines {
    double lineHeight = slider.toDouble(); // 현재 글꼴 크기를 줄 높이로 사용
    if (lineHeight == 0) return 1;
    return (availableHeight / lineHeight).floor();
  }

  Row buildAppBar() {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: _toggleAlign,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            // need if TextSpan is null
            if (controller.text.isEmpty) {
              Navigator.pop(context);
            } else {
              TextSpan text = TextSpan(
                  text: controller.text,
                  style: TextStyle(
                    color: currentColor,
                    fontSize: slider.toDouble(),
                  ));

              Navigator.pop(
                context,
                text,
              );
            }
          },
          color: Colors.white,
          padding: const EdgeInsets.all(15),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: <Widget>[
            Container(
              constraints: const BoxConstraints.expand(),
              child: Center(
                child: TextField(
                  controller: controller,
                  textAlign: align,
                  enableSuggestions: false,
                  autocorrect: false,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: currentColor,
                    fontSize: slider.toDouble(),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(10),
                    labelStyle: TextStyle(decoration: TextDecoration.none),
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.center,
                  minLines: 1,
                  maxLines: maxLines, //<- fix
                  autofocus: true,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, 0),
              child: buildAppBar(),
            ),
            if (isKeyboardActive)
              Positioned(
                bottom: 25,
                left: 0,
                child: Row(
                  children: [
                    ColorButton(
                      color: Colors.yellow,
                      onTap: (color) {
                        showModalBottomSheet(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              topLeft: Radius.circular(10),
                            ),
                          ),
                          context: context,
                          builder: (context) {
                            return Container(
                              color: Colors.black87,
                              padding: const EdgeInsets.all(20),
                              child: SingleChildScrollView(
                                child: Container(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: HueRingPicker(
                                    pickerColor: pickerColor,
                                    onColorChanged: changeColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    for (int i = 0; i < colorList.length; i++)
                      ColorButton(
                        color: colorList[i],
                        onTap: (color) => changeColor(color),
                        isSelected: colorList[i] == currentColor,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
