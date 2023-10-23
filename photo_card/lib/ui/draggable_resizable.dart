import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_card/lib.dart';

class DraggableResizable extends StatefulWidget {
  const DraggableResizable({
    Key? key,
    required this.layerItem,
    required this.canTransform,
    this.onTap,
    this.onTapDown,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
  }) : super(key: key);

  final ValueChanged<LayerItem>? onTap;
  final ValueChanged<LayerItem>? onTapDown;
  final ValueChanged<LayerItem>? onDelete;
  final ValueChanged<LayerItem>? onDragStart;
  final ValueChanged<LayerItem>? onDragEnd;

  final LayerItem layerItem;

  final bool canTransform;

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
  bool isFocus = false;

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
        Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: _DraggablePoint(
              ignorePointer: widget.layerItem.type.ignorePoint,
              onTap: () {
                widget.onTap?.call(layerItem);
              },
              onTapDown: () {
                widget.onTapDown?.call(layerItem);
              },
              onDragStart: (d) {
                setState(() {
                  isFocus = true;
                });
                widget.onDragStart?.call(layerItem);
                startingFingerPositionFromObject = d;
              },
              onDragEnd: () {
                setState(() {
                  isFocus = false;
                });
                _handleDeleteAction(false);
                widget.onDragEnd?.call(layerItem);
              },
              onDrag: widget.layerItem.type.isDraggable
                  ? (d, focalPoint) async {
                      offset = Offset(offset.dx + d.dx, offset.dy + d.dy);

                      currentFingerPosition = startingFingerPositionFromObject + offset;
                      _handleDeleteAction(true);
                    }
                  : null,
              onScale: widget.layerItem.type.isScalable ? (s) => _handleScale(s) : null,
              onRotate: widget.layerItem.type.isRotatable ? (a) => angle = a : null,
              child: ChildLayerItem(layerItem: layerItem, customSize: size),
            ),
          ),
        ),
        Visibility(
          visible: isFocus && widget.layerItem.type.isObject,
          child: DeleteArea(currentFingerPosition: currentFingerPosition),
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
}

class _DraggablePoint extends StatefulWidget {
  const _DraggablePoint({
    Key? key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onDrag,
    this.onDragStart,
    this.onDragEnd,
    this.onScale,
    this.onRotate,
    this.ignorePointer = false,
  }) : super(key: key);

  final Widget child;
  final void Function(Offset p1, Offset p2)? onDrag;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
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
        onTap: () {
          widget.onTap?.call();
        },
        onTapDown: (details) {
          initPoint = details.localPosition;
          widget.onTapDown?.call();
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
