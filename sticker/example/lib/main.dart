import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sticker/stickerview.dart';

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
                        child: Image.asset(
                          'assets/images/g.png',
                        ),
                        key: UniqueKey(),
                      ));
                    });
                  },
                  icon: const Icon(Icons.add)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.save_alt),
            onPressed: () async {
              Uint8List? imageData = await StickerView.saveAsUint8List(ImageQuality.high);
              if (imageData != null) {
                var imageName = DateTime.now().microsecondsSinceEpoch.toString();
                var appDocDir = await getApplicationDocumentsDirectory();
                String imagePath = appDocDir.path + imageName + '.png';
                File imageFile = File(imagePath);
                imageFile.writeAsBytesSync(imageData);
                // ignore: avoid_print
                print("imageFile::::$imageFile");
              }
            },
          ),
          body: Center(
            // Sticker Editor View
            child: StickerView(
              // List of Stickers
              backgroundImage:
                  'https://marketplace.canva.com/EAD2xI0GoM0/1/0/1600w/canva-%ED%95%98%EB%8A%98-%EC%95%BC%EC%99%B8-%EC%9E%90%EC%97%B0-%EC%98%81%EA%B0%90-%EC%9D%B8%EC%9A%A9%EB%AC%B8-%EB%8D%B0%EC%8A%A4%ED%81%AC%ED%86%B1-%EB%B0%B0%EA%B2%BD%ED%99%94%EB%A9%B4-rssvAb9JL4I.jpg',
              stickerList: stickers,
              // [

              // Sticker(
              //   child: Image.network(
              //       "https://images.unsplash.com/photo-1640113292801-785c4c678e1e?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=736&q=80"),
              //   // must have unique id for every Sticker
              //   key: UniqueKey(),
              // ),
              // Sticker(
              //   child: Image.asset('assets/images/g.png'),
              //   key: UniqueKey(),
              //   // isText: true,
              // ),
              // Sticker(
              //   child: const Text("Hello"),
              //   key: UniqueKey(),
              //   isText: true,
              // ),
              // Sticker(
              //   child: const Text("Hello"),
              //   key: UniqueKey(),
              //   isText: true,
              // ),
              // ],
            ),
          )),
    );
  }
}
