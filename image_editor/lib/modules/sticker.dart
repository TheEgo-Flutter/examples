import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Stickers extends StatefulWidget {
  const Stickers({super.key, required this.stickers});
  final List<String> stickers;
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
                  children: widget.stickers.map((String sticker) {
                    late Widget image;
                    //if .json contains sticker type
                    if (sticker.contains('.json')) {
                      image = Lottie.asset(
                        'assets/$sticker',
                      );
                    } else {
                      image = Image.asset(
                        'assets/$sticker',
                      );
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
