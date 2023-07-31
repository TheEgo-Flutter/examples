import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../image_editor_plus.dart';
import '../layers/layer.dart';

class DraggableResizable extends StatefulWidget {
  DraggableResizable({
    Key? key,
    required this.layer,
    BoxConstraints? constraints,
    this.onLayerTapped,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
    this.canTransform = false,
  })  : constraints = constraints ?? BoxConstraints.loose(Size.infinite),
        super(key: key);
  final LayerData layer;
  final VoidCallback? onDelete;
  final VoidCallback? onLayerTapped;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  final bool canTransform;
  final BoxConstraints constraints;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  late Size size;
  late BoxConstraints constraints;
  double angle = 0;
  Offset position = Offset.zero;
  bool isCenteredHorizontally = false;
  bool isCenteredVertically = false;

  @override
  void initState() {
    super.initState();
    size = widget.layer.size;
    constraints = widget.constraints;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _setInitialPositionIfNeeded(constraints);
        _setNormalizedSizeAndPosition(constraints);

        if (this.constraints != constraints) {
          this.constraints = constraints;
        }

        return Stack(
          children: <Widget>[
            if (selectedAssetId == widget.layer.key)
              ..._buildCenterLine(constraints, isCenteredHorizontally, isCenteredVertically),
            Positioned(
              top: position.dy,
              left: position.dx,
              child: _buildDraggablePoint(),
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
    final newSize = Size(normalizedWidth, normalizedHeight);

    if (widget.constraints.isSatisfiedBy(newSize)) size = newSize;

    final normalizedLeft = position.dx;
    final normalizedTop = position.dy;

    position = Offset(normalizedLeft, normalizedTop);
  }

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

  _DraggablePoint _buildDraggablePoint() {
    return _DraggablePoint(
      onLayerTapped: () => widget.onLayerTapped?.call(),
      onDragStart: () => widget.onDragStart?.call(),
      onDragEnd: () => widget.onDragEnd?.call(),
      onDrag: widget.canTransform ? (d) => _handleDrag(d, constraints) : null,
      onScale: widget.canTransform ? (s) => _handleScale(s, constraints) : null,
      onRotate: widget.canTransform ? (a) => _handleRotate(a) : null,
      child: _buildTransform(),
    );
  }

  void _handleDrag(Offset delta, BoxConstraints constraints) {
    setState(() {
      position = Offset(position.dx + delta.dx, position.dy + delta.dy);
      isCenteredHorizontally = _checkIfCenteredHorizontally(position, size, constraints.maxWidth);
      isCenteredVertically = _checkIfCenteredVertically(position, size, constraints.maxHeight);
    });
  }

  void _handleScale(double scale, BoxConstraints constraints) {
    log('onScale');
    final updatedSize = Size(
      size.width * scale,
      size.height * scale,
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

  void _handleRotate(double rotation) {
    log('onRotate');
    setState(() {
      angle = rotation;
    });
  }

  bool _checkIfCenteredHorizontally(Offset position, Size size, double width) {
    final centerX = width / 2;
    final widgetCenterX = position.dx + size.width / 2;
    return (centerX - widgetCenterX).abs() < 5;
  }

  bool _checkIfCenteredVertically(Offset position, Size size, double height) {
    final centerY = height / 2;
    final widgetCenterY = position.dy + size.height / 2;
    return (centerY - widgetCenterY).abs() < 5;
  }

  bool _isSizeTooSmall(Size size) {
    return size.width < 64 || size.height < 64;
  }

  bool _isSizeTooLarge(Size size, BoxConstraints constraints) {
    return size.width > constraints.maxWidth || size.height > constraints.maxHeight;
  }

  Transform _buildTransform() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(1.0)
        ..rotateZ(angle),
      child: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: widget.canTransform ? Colors.blue : Colors.transparent,
          ),
        ),
        child: widget.layer.object,
      ),
    );
  }
}

class _DraggablePoint extends StatefulWidget {
  _DraggablePoint({
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
