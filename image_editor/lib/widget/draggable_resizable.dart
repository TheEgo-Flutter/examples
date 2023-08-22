import 'dart:developer';
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
  final void Function(Offset offset, LayerItem layerItem, LayerItemStatus status)? onDelete;
  final ValueChanged<LayerItem>? onDragStart;
  final ValueChanged<LayerItem>? onDragEnd;
  final bool isFocus;
  final LayerItem layerItem;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  // 기본값
  Offset _offset = Offset.zero;
  double _angle = 0;
  double _scale = 1.0;
  // LayerItem값
  Size size = Size.zero;
  Offset offset = Offset.zero;
  // 센터링 검사
  bool isCenteredHorizontally = false;
  bool isCenteredVertically = false;

  @override
  void initState() {
    super.initState();
    _angle = widget.layerItem.angle;
    LayerItem item = widget.layerItem;
    final aspectRatio = item.rect.size.width / item.rect.size.height;

    offset = offset == Offset.zero ? getCenterOffset(cardBoxRect, item.rect.size) : item.rect.topLeft;
    size = Size(item.rect.size.width, item.rect.size.width / aspectRatio);
  }

  // 생략: buildChild 메서드

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (widget.isFocus) ..._buildCenterLine(isCenteredHorizontally, isCenteredVertically),
        Positioned(
          top: offset.dy,
          left: offset.dx,
          child: _buildDraggablePoint(),
        ),
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

  LayerItem get layerItem => widget.layerItem.copyWith(
        rect: offset & size,
        angle: _angle,
      );
  Offset startingFingerPositionFromObject = Offset.zero;
  Offset currentFingerPosition = Offset.zero;
  // 드래그 가능한 포인트 생성
  Widget _buildDraggablePoint() {
    if (widget.layerItem.isFixed) {
      return buildChild();
    }

    return _DraggablePoint(
      onLayerTapped: () => widget.onLayerTapped?.call(layerItem),
      onDragStart: (d) {
        widget.onDragStart?.call(layerItem);
        startingFingerPositionFromObject = d;
      },
      onDragEnd: () {
        widget.onDelete?.call(currentFingerPosition, layerItem, LayerItemStatus.completed);
        widget.onDragEnd?.call(layerItem);
      },
      onDrag: widget.isFocus
          ? (d, focalPoint) async {
              setState(() {
                offset = Offset(offset.dx + d.dx, offset.dy + d.dy);
                isCenteredHorizontally = _checkIfCentered(offset, size, cardBoxRect.size.width, Axis.horizontal);
                isCenteredVertically = _checkIfCentered(offset, size, cardBoxRect.size.height, Axis.vertical);
              });

              currentFingerPosition = startingFingerPositionFromObject + offset;
              widget.onDelete?.call(currentFingerPosition, layerItem, LayerItemStatus.dragging);
            }
          : null,
      onScale: widget.isFocus ? (s) => _handleScale(s) : null,
      onRotate: widget.isFocus
          ? (a) => setState(() {
                _angle = a;
              })
          : null,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: _angle,
          child: Transform.scale(
            scale: _scale,
            child: buildChild(),
          ),
        ),
      ),
    );
  }

  // 스케일 핸들러
  void _handleScale(double scale) {
    log('onScale');
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

    setState(() {
      size = updatedSize;
      offset = updatedPosition;
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
      case LayerType.sticker:
        return Container(
          height: size.height,
          width: size.width,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2,
              color: widget.isFocus ? Colors.blue : Colors.transparent,
            ),
          ),
          child: widget.layerItem.object,
        );
      case LayerType.text:
        TextEditorStyle textEditorStyle = widget.layerItem.object as TextEditorStyle;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 2,
              color: widget.isFocus ? Colors.blue : Colors.transparent,
            ),
          ),
          child: Container(
            height: size.height,
            width: size.width,
            margin: const EdgeInsets.all(textFieldSpacing),
            decoration: BoxDecoration(
              color: textEditorStyle.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextFormField(
              readOnly: true,
              enabled: !true,
              initialValue: textEditorStyle.text,
              textAlign: textEditorStyle.textAlign,
              style: textEditorStyle.textStyle.copyWith(
                  fontSize: textEditorStyle.textStyle.fontSize! * (size.width / widget.layerItem.rect.size.width)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(textFieldSpacing),
              ),
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.multiline,
              enableSuggestions: false,
              autocorrect: false,
              maxLines: null,
              autofocus: true,
            ),
          ),
        );
      case LayerType.image:
        return SizedBox(
          height: size.height,
          width: size.width,
          child: widget.layerItem.object,
        );
      case LayerType.background:
      case LayerType.drawing:
      case LayerType.frame:
      default:
        return IgnorePointer(
          ignoring: true,
          child: SizedBox(
            height: size.height,
            width: size.width,
            child: widget.layerItem.object,
          ),
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
