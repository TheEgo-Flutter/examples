import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_card/lib.dart';

class DraggableResizable extends StatefulWidget {
  const DraggableResizable({
    Key? key,
    required this.layerItem,
    this.onLayerTapped,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
    this.isFocus = false,
  }) : super(key: key);

  final ValueChanged<LayerItem>? onLayerTapped;
  final ValueChanged<LayerItem>? onDelete;
  final ValueChanged<LayerItem>? onDragStart;
  final ValueChanged<LayerItem>? onDragEnd;

  final bool isFocus;
  final LayerItem layerItem;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> with SingleTickerProviderStateMixin {
  Offset get offset => _offset;
  Offset _offset = Offset.zero;
  set offset(Offset value) {
    _offset = value;
    setState(() {});
  }

  Size get size => _size;
  Size _size = Size.zero;
  set size(Size value) {
    _size = value;
    setState(() {});
  }

  double get angle => _angle;
  double _angle = 0;
  set angle(double value) {
    _angle = value;
    setState(() {});
  }

  dynamic get object => _object;
  dynamic _object;
  set object(dynamic value) {
    _object = value;
    setState(() {});
  }

  Rect get rect => offset & size;
  double get scale => (size.width / widget.layerItem.rect.size.width);

  LayerItem get layerItem => widget.layerItem.copyWith(
        rect: offset & size,
        angle: angle,
        object: object,
      );

  bool isCenteredHorizontally = false;
  bool isCenteredVertically = false;

  Offset startingFingerPositionFromObject = Offset.zero;
  Offset currentFingerPosition = Offset.zero;

  bool isInDeleteArea = false;

  @override
  void initState() {
    super.initState();
    final item = widget.layerItem;
    final aspectRatio = item.rect.size.width / item.rect.size.height;
    angle = widget.layerItem.angle;
    object = widget.layerItem.object;
    size = Size(item.rect.size.width, item.rect.size.width / aspectRatio);
    offset = item.rect.topLeft;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleDeleteAction(
    bool isDragging,
  ) async {
    if (!(widget.layerItem.type.isObject)) return;
    if (!CardRect().deleteRect.contains(currentFingerPosition)) {
      isInDeleteArea = false;

      return;
    } else {
      if (isDragging) {
        if (!isInDeleteArea) HapticFeedback.lightImpact();

        isInDeleteArea = true;
      } else {
        widget.onDelete?.call(layerItem);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (widget.isFocus) ..._buildCenterLine(GlobalRect().cardRect, isCenteredHorizontally, isCenteredVertically),
        Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: _DraggablePoint(
              // key: widget.key,
              ignorePointer: widget.layerItem.type.ignorePoint,
              onLayerTapped: () {
                print('onLayerTapped');
                widget.onLayerTapped?.call(layerItem);
              },
              onDragStart: (d) {
                print('onDragStart');
                widget.onDragStart?.call(layerItem);
                startingFingerPositionFromObject = d;
              },
              onDragEnd: () {
                _handleDeleteAction(false);
                widget.onDragEnd?.call(layerItem);
              },
              onDrag: widget.layerItem.type.isDraggable && widget.isFocus
                  ? (d, focalPoint) async {
                      print('onDrag');
                      offset = Offset(offset.dx + d.dx, offset.dy + d.dy);
                      isCenteredHorizontally =
                          _checkIfCentered(offset, size, GlobalRect().cardRect.size.width, Axis.horizontal);
                      isCenteredVertically =
                          _checkIfCentered(offset, size, GlobalRect().cardRect.size.height, Axis.vertical);
                      currentFingerPosition = startingFingerPositionFromObject + offset;
                      _handleDeleteAction(true);
                    }
                  : null,
              onScale: widget.layerItem.type.isScalable && widget.isFocus ? (s) => _handleScale(s) : null,
              onRotate: widget.layerItem.type.isRotatable && widget.isFocus ? (a) => angle = a : null,
              child: ChildLayerItem(layerItem: layerItem, customSize: size),
            ),
          ),
        ),
        if (widget.isFocus)
          DeleteArea(
            visible: widget.layerItem.type.isObject,
          ),
      ],
    );
  }

  void _handleScale(double scale) {
    final updatedSize = Size(
      widget.layerItem.rect.size.width * scale,
      widget.layerItem.rect.size.height * scale,
    );

    final midX = offset.dx + (size.width / 2);
    final midY = offset.dy + (size.height / 2);
    final updatedPosition = Offset(
      midX - (updatedSize.width / 2),
      midY - (updatedSize.height / 2),
    );

    size = updatedSize;
    offset = updatedPosition;
  }

  bool _checkIfCentered(Offset position, Size size, double canvasDimen, Axis axis) {
    final center = canvasDimen / 2;
    final widgetCenter = (axis == Axis.vertical ? position.dy : position.dx) + size.width / 2;
    return (center - widgetCenter).abs() < 5;
  }

  List<Widget> _buildCenterLine(Rect standard, bool isCenteredHorizontally, bool isCenteredVertically) {
    return [
      Positioned(
        top: standard.size.height / 2,
        left: 0,
        right: 0,
        child: Container(
          height: 1,
          color: isCenteredVertically ? Colors.red : Colors.transparent,
        ),
      ),
      Positioned(
        left: standard.size.width / 2,
        top: 0,
        bottom: 0,
        child: Container(
          width: 1,
          color: isCenteredHorizontally ? Colors.red : Colors.transparent,
        ),
      ),
    ];
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
    this.ignorePointer = false,
  }) : super(key: key);

  final Widget child;
  final void Function(Offset p1, Offset p2)? onDrag;
  final VoidCallback? onLayerTapped;
  final ValueSetter<Offset>? onDragStart;
  final VoidCallback? onDragEnd;

  final ValueSetter<double>? onScale;
  final ValueSetter<double>? onRotate;
  final bool ignorePointer;

  @override
  _DraggablePointState createState() => _DraggablePointState();
}

class _DraggablePointState extends State<_DraggablePoint> {
  Offset initPoint = Offset.zero;
  double angle = 0;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.ignorePointer,
      child: GestureDetector(
        // onTap: () {
        //   print('aaaaa');
        //   return widget.onLayerTapped?.call();
        // },
        onTapDown: (details) {
          print('aaaaa');
          initPoint = details.localPosition;
          widget.onLayerTapped?.call();
        },
        onScaleStart: (details) {
          initPoint = details.localFocalPoint;
          widget.onDragStart?.call(details.localFocalPoint);
        },
        onScaleEnd: (details) => widget.onDragEnd?.call(),
        onScaleUpdate: (details) {
          final dx = details.localFocalPoint.dx - initPoint.dx;
          final dy = details.localFocalPoint.dy - initPoint.dy;

          final angleInRadians = -angle * (math.pi / 180.0);
          final rotatedDx = dx * math.cos(angleInRadians) - dy * math.sin(angleInRadians);
          final rotatedDy = dx * math.sin(angleInRadians) + dy * math.cos(angleInRadians);

          initPoint = details.localFocalPoint;
          widget.onDrag?.call(Offset(rotatedDx, rotatedDy), initPoint);

          if (details.pointerCount > 1) {
            widget.onScale?.call(details.scale);
            widget.onRotate?.call(details.rotation);
          }
        },
        child: widget.child,
      ),
    );
  }
}
