import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_sticker/sticker.dart';
// import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Sticker> stickers = [];
  File? imageFile;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      stickers.add(Sticker(
                        key: UniqueKey(),
                        child: Image.asset(
                          'assets/images/sample.png',
                        ),
                      ));
                    });
                  },
                  icon: const Icon(Icons.add)),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: imageFile != null
                                ? Image.file(imageFile!)
                                : const Center(child: Text(' no image selected')),
                          );
                        });
                  },
                  child: const Icon(Icons.image)),
              const SizedBox(
                width: 10,
              ),
              FloatingActionButton(
                child: const Icon(Icons.save_alt),
                onPressed: () async {
                  Uint8List? imageData = await StickerView.saveAsUint8List(ImageQuality.high);
                  // if (imageData != null) {
                  //   var imageName = DateTime.now().microsecondsSinceEpoch.toString();
                  //   var appDocDir = await getApplicationDocumentsDirectory();
                  //   String imagePath = '${appDocDir.path}$imageName.png';
                  //   imageFile = File(imagePath);
                  //   imageFile!.writeAsBytesSync(imageData);
                  //   // ignore: avoid_print
                  //   print("imageFile::::$imageFile");
                  // }
                },
              ),
            ],
          ),
          body: Center(
            // Sticker Editor View
            child: StickerView(
              // List of Stickers
              // free network image

              backgroundImage: 'assets/images/bg.png',
              stickerList: stickers,
            ),
          )),
    );
  }
}
