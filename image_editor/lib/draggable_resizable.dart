import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'layer_manager.dart';

class DraggableResizable extends StatefulWidget {
  const DraggableResizable({
    required key,
    required this.layerItem,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
    this.isFocus = false,
  }) : super(key: key);

  final VoidCallback? onDelete;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final bool isFocus;
  final LayerItem layerItem;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  Size size = Size.zero;
  double angle = 0;
  Offset position = Offset.zero;
  bool isCenteredHorizontally = false;
  bool isCenteredVertically = false;

  @override
  void initState() {
    super.initState();
    size = widget.layerItem.size;
  }

  // 생략: buildChild 메서드

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _setInitialPositionIfNeeded(constraints);
        _setNormalizedSizeAndPosition(constraints);

        return Stack(
          children: <Widget>[
            if (widget.isFocus) ..._buildCenterLine(constraints, isCenteredHorizontally, isCenteredVertically),
            Positioned(
              top: position.dy,
              left: position.dx,
              child: _buildDraggablePoint(constraints),
            ),
          ],
        );
      },
    );
  }

  void _setInitialPositionIfNeeded(BoxConstraints constraints) {
    if (position == Offset.zero) {
      position = Offset(
        constraints.maxWidth / 2 - (size.width / 2),
        constraints.maxHeight / 2 - (size.height / 2),
      );
    }
  }

  void _setNormalizedSizeAndPosition(BoxConstraints constraints) {
    final aspectRatio = size.width / size.height;
    final normalizedWidth = size.width;
    final normalizedHeight = normalizedWidth / aspectRatio;
    final normalizedLeft = position.dx;
    final normalizedTop = position.dy;

    size = Size(normalizedWidth, normalizedHeight);
    position = Offset(normalizedLeft, normalizedTop);
  }

  // 중앙선 생성
  List<Widget> _buildCenterLine(BoxConstraints constraints, bool isCenteredHorizontally, bool isCenteredVertically) {
    return [
      Positioned(
        top: constraints.maxHeight / 2,
        left: 0,
        right: 0,
        child: Container(
          height: 1,
          color: isCenteredVertically ? Colors.red : Colors.transparent,
        ),
      ),
      Positioned(
        left: constraints.maxWidth / 2,
        top: 0,
        bottom: 0,
        child: Container(
          width: 1,
          color: isCenteredHorizontally ? Colors.red : Colors.transparent,
        ),
      )
    ];
  }

  // 드래그 가능한 포인트 생성
  Widget _buildDraggablePoint(BoxConstraints constraints) {
    if (widget.layerItem.isFixed) {
      return IgnorePointer(
        ignoring: true,
        child: _DraggablePoint(
          child: _buildTransform(constraints),
        ),
      );
    }
    return _DraggablePoint(
      onLayerTapped: () => widget.onDragStart?.call(),
      onDragStart: () => widget.onDragStart?.call(),
      onDragEnd: () => widget.onDragEnd?.call(),
      onDrag: widget.isFocus ? (d) => _handleDrag(d, constraints) : null,
      onScale: widget.isFocus ? (s) => _handleScale(s, constraints) : null,
      onRotate: widget.isFocus ? (a) => _handleRotate(a) : null,
      child: _buildTransform(constraints),
    );
  }

  // 드래그 핸들러
  void _handleDrag(Offset delta, BoxConstraints constraints) {
    setState(() {
      position = Offset(position.dx + delta.dx, position.dy + delta.dy);
      isCenteredHorizontally = _checkIfCentered(position, size, constraints.maxWidth, Axis.horizontal);
      isCenteredVertically = _checkIfCentered(position, size, constraints.maxHeight, Axis.vertical);
    });
  }

  // 스케일 핸들러
  void _handleScale(double scale, BoxConstraints constraints) {
    log('onScale');
    final updatedSize = Size(
      widget.layerItem.size.width * scale,
      widget.layerItem.size.height * scale,
    );

    if (_isSizeTooSmall(updatedSize) || _isSizeTooLarge(updatedSize, constraints)) {
      return;
    }

    final midX = position.dx + (size.width / 2);
    final midY = position.dy + (size.height / 2);
    final updatedPosition = Offset(
      midX - (updatedSize.width / 2),
      midY - (updatedSize.height / 2),
    );

    setState(() {
      size = updatedSize;
      position = updatedPosition;
    });
  }

  // 로테이션 핸들러
  void _handleRotate(double rotation) {
    log('onRotate');
    setState(() {
      angle = rotation;
    });
  }

  // 센터링 검사 메서드 (수평/수직)
  bool _checkIfCentered(Offset position, Size size, double canvasDimen, Axis axis) {
    final center = canvasDimen / 2;
    final widgetCenter = (axis == Axis.vertical ? position.dy : position.dx) + size.width / 2;
    return (center - widgetCenter).abs() < 5;
  }

  // 사이즈가 너무 작은지 검사
  bool _isSizeTooSmall(Size size) {
    return size.width < 64 || size.height < 64;
  }

  // 사이즈가 너무 큰지 검사
  bool _isSizeTooLarge(Size size, BoxConstraints constraints) {
    return size.width > constraints.maxWidth || size.height > constraints.maxHeight;
  }

  // Transform 위젯 빌드
  Widget _buildTransform(BoxConstraints constraints) {
    return Transform.rotate(
      angle: angle,
      child: Transform.scale(
        scale: 1.0,
        child: buildChild(constraints),
      ),
    );
  }

  Widget buildChild(BoxConstraints constraints) {
    const double iconArea = 16;
    switch (widget.layerItem.type) {
      case LayerType.sticker:
      case LayerType.text:
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(iconArea / 2),
              child: Container(
                height: size.height,
                width: size.width,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: widget.isFocus ? Colors.blue : Colors.transparent,
                  ),
                ),
                child: widget.layerItem.widget, // LayerItem의 widget을 사용
              ),
            ),
            widget.isFocus
                ? Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: iconArea,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink()
          ],
        );

      case LayerType.drawing:
      case LayerType.frame:
      case LayerType.background:
      default:
        return SizedBox(
          height: size.height,
          width: size.width,

          child: widget.layerItem.widget, // LayerItem의 widget을 사용
        );
    }
  }
}

class _DraggablePoint extends StatefulWidget {
  const _DraggablePoint({
    Key? key,
    required this.child,
    this.onLayerTapped,
    this.onDrag,
    this.onDragStart,
    this.onDragEnd,
    this.onScale,
    this.onRotate,
  }) : super(key: key);

  final Widget child;
  final ValueSetter<Offset>? onDrag;
  final VoidCallback? onLayerTapped;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final ValueSetter<double>? onScale;
  final ValueSetter<double>? onRotate;

  @override
  _DraggablePointState createState() => _DraggablePointState();
}

class _DraggablePointState extends State<_DraggablePoint> {
  Offset initPoint = Offset.zero;
  double angle = 0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onLayerTapped?.call(),
      onScaleStart: (details) {
        initPoint = details.localFocalPoint;
        widget.onDragStart?.call();
      },
      onScaleEnd: (details) {
        widget.onDragEnd?.call();
      },
      onScaleUpdate: (details) {
        final dx = details.localFocalPoint.dx - initPoint.dx;
        final dy = details.localFocalPoint.dy - initPoint.dy;

        final angleInRadians = -angle * (math.pi / 180.0);
        final rotatedDx = dx * math.cos(angleInRadians) - dy * math.sin(angleInRadians);
        final rotatedDy = dx * math.sin(angleInRadians) + dy * math.cos(angleInRadians);

        initPoint = details.localFocalPoint;
        widget.onDrag?.call(Offset(rotatedDx, rotatedDy));

        if (details.pointerCount > 1) {
          widget.onScale?.call(details.scale);
          widget.onRotate?.call(details.rotation);
        }
      },
      child: widget.child,
    );
  }
}
