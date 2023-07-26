part of 'options.dart';

/// Not yet implemented, just reserved api
class DrawOption extends Option {
  final List<DrawPart> parts = [];

  DrawOption();

  @override
  bool get canIgnore => parts.isEmpty;

  @override
  String get key => 'draw';

  @override
  Map<String, Object> get transferValue => {
        "parts": parts
            .map((e) => {
                  'key': e.key,
                  'value': e.transferValue,
                })
            .toList(),
      };

  void addDrawPart(DrawPart part) {
    parts.add(part);
  }
}

abstract class DrawPart implements TransferValue {
  const DrawPart();

  Map<String, Object> offsetValue(Offset o) {
    return ConvertUtils.offset(o);
  }

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(transferValue);
  }
}

class DrawPaint extends DrawPart {
  final Color color;
  final double lineWeight;
  final PaintingStyle paintingStyle;

  const DrawPaint({
    this.color = Colors.black,
    this.lineWeight = 2,
    this.paintingStyle = PaintingStyle.fill,
  });

  factory DrawPaint.paint(Paint paint) {
    return DrawPaint(
      color: paint.color,
      lineWeight: paint.strokeWidth,
      paintingStyle: paint.style,
    );
  }

  @override
  bool get canIgnore => false;

  @override
  String get key => 'paint';

  @override
  Map<String, Object> get transferValue => {
        'color': ConvertUtils.color(color),
        'lineWeight': lineWeight,
        'paintStyleFill': paintingStyle == PaintingStyle.fill,
      };

  Map<String, Object> get values => {
        key: transferValue,
      };
}

mixin _HavePaint on TransferValue {
  DrawPaint get paint;

  Map<String, Object> get values;

  @override
  Map<String, Object> get transferValue =>
      <String, Object>{}..addAll(values)..addAll(paint.values);
}

class LineDrawPart extends DrawPart with _HavePaint {
  final Offset start;
  final Offset end;
  final DrawPaint paint;

  LineDrawPart({
    required this.start,
    required this.end,
    required this.paint,
  });

  @override
  bool get canIgnore => false;

  @override
  String get key => 'line';

  @override
  Map<String, Object> get values => {
        'start': offsetValue(start),
        'end': offsetValue(end),
      };
}

class PointDrawPart extends DrawPart with _HavePaint {
  final List<Offset> points = [];
  final DrawPaint paint;

  PointDrawPart({
    this.paint = const DrawPaint(),
  });

  @override
  bool get canIgnore => false;

  @override
  String get key => 'point';

  @override
  Map<String, Object> get values => {
        'offset': points.map((e) => ConvertUtils.offset(e)).toList(),
      };
}

class RectDrawPart extends DrawPart with _HavePaint {
  final Rect rect;
  final DrawPaint paint;

  RectDrawPart({
    required this.rect,
    this.paint = const DrawPaint(),
  });

  @override
  bool get canIgnore => false;

  @override
  String get key => 'rect';

  @override
  Map<String, Object> get values => {
        'rect': ConvertUtils.rect(rect),
      };
}

class OvalDrawPart extends DrawPart with _HavePaint {
  final DrawPaint paint;
  final Rect rect;

  OvalDrawPart({
    required this.rect,
    this.paint = const DrawPaint(),
  });

  @override
  bool get canIgnore => false;

  @override
  String get key => 'oval';

  @override
  Map<String, Object> get values => {
        'rect': ConvertUtils.rect(rect),
      };
}

class PathDrawPart extends DrawPart with _HavePaint {
  final List<_PathPart> parts = [];

  @override
  final DrawPaint paint;

  final bool autoClose;

  PathDrawPart({
    this.autoClose = false,
    this.paint = const DrawPaint(),
  });

  @override
  bool get canIgnore => parts.isEmpty;

  void move(Offset point) {
    parts.add(
      _MovePathPart(point),
    );
  }

  void lineTo(Offset point, DrawPaint paint) {
    parts.add(
      _LineToPathPart(point),
    );
  }

  /// The parameters of iOS and Android/flutter are inconsistent and need to be converted.
  /// For the time being, consistency cannot be guaranteed, delete it first.
  ///
  /// Consider adding back in future versions (may not)
  // void arcTo(Rect rect, double startAngle, double sweepAngle, bool useCenter,
  //     DrawPaint paint) {
  //   parts.add(
  //     _ArcToPathPart(
  //       rect: rect,
  //       startAngle: startAngle,
  //       sweepAngle: sweepAngle,
  //       useCenter: useCenter,
  //     ),
  //   );
  // }

  void bezier2To(Offset target, Offset control) {
    parts.add(
      _BezierPathPart(
        target: target,
        control1: control,
        control2: null,
        kind: 2,
      ),
    );
  }

  void bezier3To(Offset target, Offset control1, Offset control2) {
    parts.add(
      _BezierPathPart(
        target: target,
        control1: control1,
        control2: control2,
        kind: 3,
      ),
    );
  }

  void bezierTo({
    required Offset target,
    Offset? control1,
    Offset? control2,
    DrawPaint paint = const DrawPaint(),
  }) {
    if (control1 == null) {
      lineTo(target, paint);
      return;
    }
    if (control2 == null) {
      bezier2To(target, control1);
      return;
    }
    bezier3To(target, control1, control2);
  }

  @override
  String get key => 'path';

  @override
  Map<String, Object> get values => {
        'autoClose': autoClose,
        'parts': parts
            .map((e) => {
                  'key': e.key,
                  'value': e.transferValue,
                })
            .toList(),
      };
}

abstract class _PathPart extends TransferValue {
  @override
  bool get canIgnore => false;
}

class _MovePathPart extends _PathPart {
  final Offset offset;

  _MovePathPart(this.offset);

  @override
  String get key => 'move';

  @override
  Map<String, Object> get transferValue => {
        'offset': ConvertUtils.offset(offset),
      };
}

class _LineToPathPart extends _PathPart {
  final Offset offset;

  _LineToPathPart(this.offset);

  @override
  String get key => 'lineTo';

  @override
  Map<String, Object> get transferValue => {
        'offset': ConvertUtils.offset(offset),
      };
}

class _BezierPathPart extends _PathPart {
  final Offset target;
  final Offset control1;
  final Offset? control2;
  final int kind;

  _BezierPathPart({
    required this.target,
    required this.control1,
    this.control2,
    required this.kind,
  }) : assert(kind == 2 || kind == 3);

  @override
  String get key => 'bezier';

  @override
  Map<String, Object> get transferValue {
    final value = <String, Object>{
      'target': ConvertUtils.offset(target),
      'c1': ConvertUtils.offset(control1),
      'kind': kind,
    };

    if (control2 != null) {
      value['c2'] = ConvertUtils.offset(control2!);
    }

    return value;
  }
}

/// ignore: unused_element
class _ArcToPathPart extends _PathPart {
  final Rect rect;
  final double startAngle;
  final double sweepAngle;
  final bool useCenter;

  _ArcToPathPart({
    required this.rect,
    required this.startAngle,
    required this.sweepAngle,
    required this.useCenter,
  });

  @override
  String get key => 'arcTo';

  @override
  Map<String, Object> get transferValue => {
        'rect': ConvertUtils.rect(rect),
        'start': startAngle,
        'sweep': sweepAngle,
        'useCenter': useCenter,
      };
}
