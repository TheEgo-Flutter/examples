import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

const _cornerDiameter = 22.0;
const _floatingActionDiameter = 18.0;
const _floatingActionPadding = 24.0;

class DraggableResizable extends StatelessWidget {
  DraggableResizable.background({
    required Key key,
    required Uint8List? uint8List,
    required Size size,
    VoidCallback? onDragStart,
    VoidCallback? onDragEnd,
    VoidCallback? onDelete,
    bool canTransform = false,
  }) : _widget = uint8List != null
            ? DraggableBase(
                key: key,
                size: size,
                onDragStart: onDragStart,
                onDragEnd: onDragEnd,
                canTransform: canTransform,
                child: Image.memory(
                  uint8List,
                  fit: BoxFit.cover,
                ),
              )
            : const SizedBox.shrink();
  DraggableResizable.object({
    required Key key,
    required Widget child,
    required Size size,
    VoidCallback? onDragStart,
    VoidCallback? onDragEnd,
    VoidCallback? onDelete,
    bool canTransform = false,
  })  : _widget = DraggableBase(
          key: key,
          size: size,
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
          canTransform: canTransform,
          child: child,
        ),
        super(key: key);

  late final Widget _widget;
  @override
  Widget build(BuildContext context) {
    return _widget;
  }
}

class DraggableBase extends StatefulWidget {
  DraggableBase({
    required key,
    required this.child,
    required this.size,
    BoxConstraints? constraints,
    this.onDragStart,
    this.onDragEnd,
    this.onDelete,
    this.canTransform = false,
  })  : constraints = constraints ?? BoxConstraints.loose(Size.infinite),
        super(key: key);

  final Widget child;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDelete;
  final bool canTransform;
  final Size size;
  final BoxConstraints constraints;

  @override
  State<DraggableBase> createState() => _DraggableBaseState();
}

class _DraggableBaseState extends State<DraggableBase> {
  late Size size;
  BoxConstraints constraints = const BoxConstraints.expand(width: 1, height: 1);
  double angle = 0.0;
  double angleDelta = 0.0;
  double baseAngle = 0.0;
  Offset position = Offset.zero;
  bool isCenteredHorizontally = false;
  bool isCenteredVertically = false;
  @override
  void initState() {
    super.initState();
    size = widget.size;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _setInitialPositionIfNeeded(constraints);
        _setNormalizedSizeAndPosition(constraints);

        final deleteButton = _FloatingActionIcon(
          key: const Key('draggableResizable_delete_floatingActionIcon'),
          iconData: Icons.delete,
          onTap: widget.onDelete,
        );

        if (this.constraints != constraints) {
          this.constraints = constraints;
        }

        return Stack(
          children: <Widget>[
            ..._buildCenterLine(constraints, isCenteredHorizontally, isCenteredVertically),
            Positioned(
              top: position.dy,
              left: position.dx,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(1.0)
                  ..rotateZ(angle),
                child: _DraggablePoint(
                    key: const Key('draggableResizable_child_draggablePoint'),
                    onDragStart: () => widget.onDragStart?.call(),
                    onDragEnd: () => widget.onDragEnd?.call(),
                    onLayerTapped: () => widget.onDragStart?.call(),
                    onDrag: (d) {
                      setState(() {
                        position = Offset(position.dx + d.dx, position.dy + d.dy);
                        isCenteredHorizontally = _checkIfCenteredHorizontally(position, size, constraints.maxWidth);
                        isCenteredVertically = _checkIfCenteredVertically(position, size, constraints.maxHeight);
                      });
                    },
                    onScale: (scale) {
                      final updatedSize = Size(
                        widget.size.width * scale,
                        widget.size.height * scale,
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
                    },
                    onRotate: (a) {
                      setState(() {
                        angle = a;
                      });
                    },
                    child: Container(
                      key: const Key('draggableResizable_child_container'),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: widget.canTransform ? Colors.blue : Colors.transparent,
                        ),
                      ),
                      child: SizedBox(
                        height: size.height,
                        width: size.width,
                        child: widget.child,
                      ),
                    )),
              ),
            ),
          ],
        );
      },
    );
  }

  void _setInitialPositionIfNeeded(BoxConstraints constraints) {
    position = position == Offset.zero
        ? Offset(
            constraints.maxWidth / 2 - (size.width / 2),
            constraints.maxHeight / 2 - (size.height / 2),
          )
        : position;
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
      onLayerTapped: () => widget.onDragStart?.call(),
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
      widget.size.width * scale,
      widget.size.height * scale,
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
      child: widget.child,
    );
  }
}

class _DraggablePoint extends StatefulWidget {
  const _DraggablePoint({
    Key? key,
    required this.child,
    this.onDrag,
    this.onScale,
    this.onRotate,
    this.onLayerTapped,
    this.onDragStart,
    this.onDragEnd,
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onLayerTapped;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final ValueSetter<Offset>? onDrag;
  final ValueSetter<double>? onScale;
  final ValueSetter<double>? onRotate;

  @override
  _DraggablePointState createState() => _DraggablePointState();
}

class _DraggablePointState extends State<_DraggablePoint> {
  Offset initPoint = Offset.zero;
  var scaleFactor = 1.0;
  var angle = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onLayerTapped?.call(),
      onScaleStart: (details) {
        initPoint = details.localFocalPoint;
        widget.onDragStart?.call();
        if (details.pointerCount > 1) {
          widget.onRotate?.call(angle);
          widget.onScale?.call(scaleFactor);
        }
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
      onScaleEnd: (details) => widget.onDragEnd?.call(),
      child: widget.child,
    );
  }
}

class _FloatingActionIcon extends StatelessWidget {
  const _FloatingActionIcon({
    Key? key,
    required this.iconData,
    this.onTap,
  }) : super(key: key);

  final IconData iconData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.hardEdge,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _floatingActionDiameter,
          width: _floatingActionDiameter,
          child: Center(
            child: Icon(
              iconData,
              color: Colors.blue,
              size: 12,
            ),
          ),
        ),
      ),
    );
  }
}
