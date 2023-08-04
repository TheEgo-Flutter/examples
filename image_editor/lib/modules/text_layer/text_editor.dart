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
  TextAlign align = TextAlign.center;
  Color pickerColor = Colors.white;
  Color currentColor = Colors.white;
  bool isKeyboardActive = false;
  double keyboardHeight = 0.0;

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
  Row buildAppBar() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.align_horizontal_left,
              color: align == TextAlign.left ? Colors.white : Colors.white.withAlpha(80)),
          onPressed: () {
            setState(() {
              align = TextAlign.left;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.align_horizontal_center,
              color: align == TextAlign.center ? Colors.white : Colors.white.withAlpha(80)),
          onPressed: () {
            setState(() {
              align = TextAlign.center;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.align_horizontal_right,
              color: align == TextAlign.right ? Colors.white : Colors.white.withAlpha(80)),
          onPressed: () {
            setState(() {
              align = TextAlign.right;
            });
          },
        ),
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(10),
                    hintText: 'Insert Your Message',
                    hintStyle: TextStyle(color: Colors.white),
                    alignLabelWithHint: true,
                  ),
                  scrollPadding: const EdgeInsets.all(20.0),
                  keyboardType: TextInputType.multiline,
                  minLines: 5,
                  maxLines: 99999,
                  style: TextStyle(
                    color: currentColor,
                    fontSize: slider.toDouble(),
                  ),
                  autofocus: true,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, 0),
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
