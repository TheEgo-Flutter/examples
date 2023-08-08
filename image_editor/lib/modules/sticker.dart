import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class Stickers extends StatefulWidget {
  const Stickers({super.key, required this.stickers});
  final List<dynamic> stickers;
  @override
  createState() => _StickersState();
}

class _StickersState extends State<Stickers> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                height: 315,
                padding: const EdgeInsets.all(0.0),
                child: GridView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisSpacing: 0.0,
                    maxCrossAxisExtent: 60.0,
                  ),
                  children: widget.stickers.map((dynamic sticker) {
                    Widget? image;
                    if (sticker is Uint8List) {
                      try {
                        // 시도해 보기: JSON 파싱
                        json.decode(utf8.decode(sticker));
                        // 성공하면 Lottie로 처리
                        image = LottieBuilder.memory(sticker);
                      } catch (e) {
                        // 실패하면 이미지로 처리
                        image = Image.memory(sticker);
                      }
                    } else if (sticker is String) {
                      if (sticker.contains('.json')) {
                        // asset의 Lottie 처리
                        image = Lottie.asset('assets/$sticker');
                      } else if (sticker.startsWith('http')) {
                        // 네트워크 이미지 처리
                        image = Image.network(sticker);
                      } else {
                        // 로컬 asset 이미지 처리
                        image = Image.asset('assets/$sticker');
                      }
                    }

                    return GridTile(
                        child: GestureDetector(
                      onTap: () {
                        Navigator.pop(
                          context,
                          image,
                        );
                      },
                      child: image,
                    ));
                  }).toList(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
