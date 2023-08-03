import 'package:flutter/material.dart';
import 'package:image_editor/utils.dart';

import 'colors_picker.dart';

class TextEditorImage extends StatefulWidget {
  const TextEditorImage({super.key});

  @override
  createState() => _TextEditorImageState();
}

class _TextEditorImageState extends State<TextEditorImage> {
  TextEditingController name = TextEditingController();
  Color currentColor = Colors.white;
  double slider = 32.0;
  TextAlign align = TextAlign.center;

  AppBar get appBar => AppBar(
        actions: <Widget>[
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
              TextSpan text = TextSpan(
                  text: name.text,
                  style: TextStyle(
                    color: currentColor,
                    fontSize: slider.toDouble(),
                  ));
              var padding = 8;
              Size getTextSize = textSize(text, context);
              Navigator.pop(
                context,
                Text.rich(
                  key: UniqueKey(),
                  text,
                  textAlign: align,
                ),
              );
            },
            color: Colors.white,
            padding: const EdgeInsets.all(15),
          )
        ],
      );
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: appBar,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(children: [
                SizedBox(
                  height: size.height / 2.2,
                  child: TextField(
                    controller: name,
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
                Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      //   SizedBox(height: 20.0),
                      const Text(
                        'Slider Color',
                      ),
                      //   SizedBox(height: 10.0),
                      Row(children: [
                        Expanded(
                          child: BarColorPicker(
                            width: 300,
                            thumbColor: Colors.white,
                            cornerRadius: 10,
                            pickMode: PickMode.color,
                            colorListener: (int value) {
                              setState(() {
                                currentColor = Color(value);
                              });
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Reset',
                          ),
                        ),
                      ]),
                      //   SizedBox(height: 20.0),
                      const Text(
                        'Slider White Black Color',
                      ),
                      //   SizedBox(height: 10.0),
                      Row(children: [
                        Expanded(
                          child: BarColorPicker(
                            width: 300,
                            thumbColor: Colors.white,
                            cornerRadius: 10,
                            pickMode: PickMode.grey,
                            colorListener: (int value) {
                              setState(() {
                                currentColor = Color(value);
                              });
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Reset',
                          ),
                        )
                      ]),
                      Container(
                        color: Colors.black,
                        child: Column(
                          children: [
                            const SizedBox(height: 10.0),
                            Center(
                              child: Text(
                                'Size Adjust'.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Slider(
                                activeColor: Colors.white,
                                inactiveColor: Colors.grey,
                                value: slider,
                                min: 0.0,
                                max: 100.0,
                                onChangeEnd: (v) {
                                  setState(() {
                                    slider = v;
                                  });
                                },
                                onChanged: (v) {
                                  setState(() {
                                    slider = v;
                                  });
                                }),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
