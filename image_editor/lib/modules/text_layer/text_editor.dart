import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../brush_painter.dart';

class TextEditor extends StatefulWidget {
  const TextEditor({super.key});

  @override
  createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();
  double slider = 32.0;
  Color currentColor = Colors.white;

  TextAlign align = TextAlign.center;
  bool get isTextEditing => focusNode.hasFocus;
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
    focusNode.addListener(_onFocusChange); // 리스너 추가
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange); // 리스너 제거
    focusNode.dispose(); // FocusNode 정리
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {}); // 포커스 상태가 변경되면 화면을 다시 그림
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
                  controller: controller, focusNode: focusNode,
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
                  maxLines: null, //<- fix
                  autofocus: true,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, 0),
              child: buildAppBar(),
            ),
            Visibility(
              visible: MediaQuery.of(context).viewInsets.bottom == 0,
              child: Positioned(
                bottom: 25,
                left: 0,
                child: colorBar(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row fontBar(BuildContext context) {
  //   return Row(
  //     children: [
  //       Container(
  //         decoration: const BoxDecoration(
  //             shape: BoxShape.circle,
  //             gradient: LinearGradient(
  //               begin: Alignment.topRight,
  //               end: Alignment.bottomLeft,
  //               stops: [
  //                 0.1,
  //                 0.4,
  //                 0.6,
  //                 0.9,
  //               ],
  //               colors: [
  //                 Colors.yellow,
  //                 Colors.red,
  //                 Colors.indigo,
  //                 Colors.teal,
  //               ],
  //             )),
  //         child: ColorButton(
  //           color: Colors.transparent,
  //           margin: const EdgeInsets.symmetric(horizontal: 8),
  //           onTap: (color) {
  //             showModalBottomSheet(
  //               context: context,
  //               builder: (context) {
  //                 return Container(
  //                   color: Colors.black87,
  //                   padding: const EdgeInsets.all(20),
  //                   child: SingleChildScrollView(
  //                     child: Container(
  //                       padding: const EdgeInsets.only(top: 16),
  //                       child: HueRingPicker(
  //                         pickerColor: currentColor,
  //                         onColorChanged: changeColor,
  //                       ),
  //                     ),
  //                   ),
  //                 );
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //       for (int i = 0; i < colorList.length; i++)
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 8.0),
  //           child: ColorButton(
  //             color: colorList[i],
  //             onTap: (color) => changeColor(color),
  //             isSelected: colorList[i] == currentColor,
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Row colorBar(BuildContext context) {
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
                    color: Colors.black87,
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
        for (int i = 0; i < colorList.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ColorButton(
              color: colorList[i],
              onTap: (color) => changeColor(color),
              isSelected: colorList[i] == currentColor,
            ),
          ),
      ],
    );
  }
}
