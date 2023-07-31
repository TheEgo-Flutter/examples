import 'package:example/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor.dart';

void main() {
  runApp(
    const MaterialApp(
      home: ImageEditorExample(),
    ),
  );
}

class ImageEditorExample extends StatefulWidget {
  const ImageEditorExample({
    super.key,
  });

  @override
  createState() => _ImageEditorExampleState();
}

class _ImageEditorExampleState extends State<ImageEditorExample> {
  Uint8List? imageData;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ImageEditor Example"),
        centerTitle: true,
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (imageData != null) SizedBox(height: 400, child: Image.memory(imageData!)),
        const SizedBox(height: 16),
        ElevatedButton(
          child: const Text("Single image editor"),
          onPressed: () async {
            var editedImage = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageEditor(
                  stickers: stickers,
                ),
              ),
            );

            // replace with edited image
            if (editedImage != null) {
              imageData = editedImage;
              setState(() {});
            }
          },
        ),
      ]),
    );
  }
}
