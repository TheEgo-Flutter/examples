import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_editor/utils/utils.dart';

import '../modules/text_layer/text_editor.dart';

enum LayerItemStatus {
  touched, // 사용자가 아이템을 처음으로 터치했을 때
  dragging, // 아이템이 드래그 중일 때
  resizing, // 아이템 크기 조정 중일 때
  rotating, // 아이템을 회전 중일 때
  completed, // 모든 동작이 완료되었을 때
}

class DraggableResizable extends StatefulWidget {
  const DraggableResizable({
    required key,
    required this.layerItem,
    this.onLayerTapped,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
    this.isFocus = false,
  }) : super(key: key);

  final ValueChanged<LayerItem>? onLayerTapped;
  final void Function(Offset offset, LayerItem layerItem, bool isDragging)? onDelete;
  final ValueChanged<LayerItem>? onDragStart;
  final ValueChanged<LayerItem>? onDragEnd;
  final bool isFocus;
  final LayerItem layerItem;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  Offset _offset = Offset.zero;
  Size _size = Size.zero;
  double _angle = 0;
  dynamic _object;
  double get _scale => (_size.width / widget.layerItem.rect.size.width);
  LayerItem get layerItem => widget.layerItem.copyWith(
        rect: _offset & _size,
        angle: _angle,
        object: _object,
      );
  // 센터링 검사
  bool isCenteredHorizontally = false;
  bool isCenteredVertically = false;

  Offset startingFingerPositionFromObject = Offset.zero;
  Offset currentFingerPosition = Offset.zero;
  @override
  void initState() {
    super.initState();
    final item = widget.layerItem;
    final aspectRatio = item.rect.size.width / item.rect.size.height;
    _angle = widget.layerItem.angle;
    _object = widget.layerItem.object;
    _size = Size(item.rect.size.width, item.rect.size.width / aspectRatio);
    _offset = item.rect.topLeft;
  }

  // 생략: buildChild 메서드

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (widget.isFocus) ..._buildCenterLine(isCenteredHorizontally, isCenteredVertically),
        Positioned(
            top: _offset.dy,
            left: _offset.dx,
            child: IgnorePointer(
              ignoring: widget.layerItem.ignorePoint,
              child: _DraggablePoint(
                onLayerTapped: () {
                  widget.onLayerTapped?.call(layerItem);
                },
                onDragStart: (d) {
                  widget.onDragStart?.call(layerItem);
                  startingFingerPositionFromObject = d;
                },
                onDragEnd: () {
                  widget.onDelete?.call(currentFingerPosition, layerItem, false);
                  widget.onDragEnd?.call(layerItem);
                },
                onDrag: widget.layerItem.isDraggable && widget.isFocus
                    ? (d, focalPoint) async {
                        setState(() {
                          _offset = Offset(_offset.dx + d.dx, _offset.dy + d.dy);
                          isCenteredHorizontally =
                              _checkIfCentered(_offset, _size, cardBoxRect.size.width, Axis.horizontal);
                          isCenteredVertically =
                              _checkIfCentered(_offset, _size, cardBoxRect.size.height, Axis.vertical);
                        });

                        currentFingerPosition = startingFingerPositionFromObject + _offset;
                        widget.onDelete?.call(currentFingerPosition, layerItem, true);
                      }
                    : null,
                onScale: widget.layerItem.isScalable && widget.isFocus ? (s) => _handleScale(s) : null,
                onRotate: widget.layerItem.isRotatable && widget.isFocus
                    ? (a) => setState(() {
                          _angle = a;
                        })
                    : null,
                child: Transform.rotate(
                  angle: _angle,
                  child: buildChild(),
                ),
              ),
            )),
      ],
    );
  }

  // 중앙선 생성
  List<Widget> _buildCenterLine(bool isCenteredHorizontally, bool isCenteredVertically) {
    return [
      Positioned(
        top: cardBoxRect.size.height / 2,
        left: 0,
        right: 0,
        child: Container(
          height: 1,
          color: isCenteredVertically ? Colors.red : Colors.transparent,
        ),
      ),
      Positioned(
        left: cardBoxRect.size.width / 2,
        top: 0,
        bottom: 0,
        child: Container(
          width: 1,
          color: isCenteredHorizontally ? Colors.red : Colors.transparent,
        ),
      ),
      //DeleteArea
    ];
  }

  // 드래그 가능한 포인트 생성

  // 스케일 핸들러
  void _handleScale(double scale) {
    final updatedSize = Size(
      widget.layerItem.rect.size.width * scale,
      widget.layerItem.rect.size.height * scale,
    );

    final midX = _offset.dx + (_size.width / 2);
    final midY = _offset.dy + (_size.height / 2);
    final updatedPosition = Offset(
      midX - (updatedSize.width / 2),
      midY - (updatedSize.height / 2),
    );

    setState(() {
      _size = updatedSize;
      _offset = updatedPosition;
    });
  }

  // 센터링 검사 메서드 (수평/수직)
  bool _checkIfCentered(Offset position, Size size, double canvasDimen, Axis axis) {
    final center = canvasDimen / 2;
    final widgetCenter = (axis == Axis.vertical ? position.dy : position.dx) + size.width / 2;
    return (center - widgetCenter).abs() < 5;
  }

  Widget buildChild() {
    switch (widget.layerItem.type) {
      case LayerType.text:
        _object as TextBoxInput;

        return TextBox(
          isReadOnly: true,
          input: _object,
        );
      case LayerType.sticker:
      case LayerType.image:
      case LayerType.background:
      case LayerType.drawing:
      case LayerType.frame:
      default:
        return SizedBox(
          height: _size.height,
          width: _size.width,
          child: widget.layerItem.object,
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
  final void Function(Offset p1, Offset p2)? onDrag;
  final VoidCallback? onLayerTapped;
  final ValueSetter<Offset>? onDragStart;
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
    );
  }
}
