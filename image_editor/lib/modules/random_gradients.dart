import 'dart:math' as math;

import 'package:flutter/rendering.dart';

class RandomGradientContainers {
  final random = math.Random();

  Color _getRandomColor() {
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }

  LinearGradient _getRandomGradient() {
    return LinearGradient(
      colors: [_getRandomColor(), _getRandomColor()],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  List<LinearGradient> buildRandomGradientContainer(int length) {
    return List.generate(
      length,
      (index) => _getRandomGradient(),
    );
  }
}
