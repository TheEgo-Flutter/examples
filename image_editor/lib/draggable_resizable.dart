import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';
import 'package:vibration/vibration.dart';

import 'layer_manager.dart';
import 'modules/text_layer/text_editor.dart';

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
  final VoidCallback? onDelete;
  final ValueChanged<LayerItem>? onDragStart;
  final ValueChanged<LayerItem>? onDragEnd;
  final bool isFocus;
  final LayerItem layerItem;

  @override
  State<DraggableResizable> createState() => _DraggableResizableState();
}

class _DraggableResizableState extends State<DraggableResizable> {
  Size size = Size.zero;
  double angle = 0;
  Offset objectPosition = Offset.zero;
  Offset _offset = Offset.zero;
  bool isCenteredHorizontally = false;
  bool isCenteredVertically = false;
  Rect deleteAreaRect = Rect.zero;
  @override
  void initState() {
    super.initState();
    size = widget.layerItem.size;
    objectPosition = widget.layerItem.position;
    angle = widget.layerItem.rotation;
  }

  // 생략: buildChild 메서드

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _setInitialPositionIfNeeded(constraints);
        _setNormalizedSizeAndPosition(constraints);
        final RenderBox renderBox = deleteAreaKey.currentContext?.findRenderObject() as RenderBox;
        final Offset deleteAreaPosition = renderBox.localToGlobal(Offset.zero) - cardBoxRect.topLeft;

        final Size size = renderBox.size;
        deleteAreaRect = Rect.fromPoints(
          deleteAreaPosition,
          deleteAreaPosition + Offset(size.width, size.height),
        );
        return Stack(
          children: <Widget>[
            if (widget.isFocus) ..._buildCenterLine(constraints, isCenteredHorizontally, isCenteredVertically),
            Positioned(
              top: deleteAreaRect.top,
              left: deleteAreaRect.left,
              child: Container(
                width: deleteAreaRect.width,
                height: deleteAreaRect.height,
                color: Colors.red.withOpacity(0.5),
              ),
            ),
            Positioned(
              top: objectPosition.dy,
              left: objectPosition.dx,
              child: _buildDraggablePoint(constraints),
            ),
          ],
        );
      },
    );
  }

  void _setInitialPositionIfNeeded(BoxConstraints constraints) {
    if (objectPosition == Offset.zero) {
      objectPosition = Offset(
        constraints.maxWidth / 2 - (size.width / 2),
        constraints.maxHeight / 2 - (size.height / 2),
      );
    }
  }

  void _setNormalizedSizeAndPosition(BoxConstraints constraints) {
    final aspectRatio = size.width / size.height;
    final normalizedWidth = size.width;
    final normalizedHeight = normalizedWidth / aspectRatio;
    final normalizedLeft = objectPosition.dx;
    final normalizedTop = objectPosition.dy;

    size = Size(normalizedWidth, normalizedHeight);
    objectPosition = Offset(normalizedLeft, normalizedTop);
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
      ),
      //DeleteArea
    ];
  }

  LayerItem get layerItem => widget.layerItem.copyWith(
        position: objectPosition,
        size: size,
        rotation: angle,
      );
  Offset startingFingerPositionFromObject = Offset.zero;
  Offset currentFingerPosition = Offset.zero;
  // 드래그 가능한 포인트 생성
  Widget _buildDraggablePoint(BoxConstraints constraints) {
    if (widget.layerItem.isFixed) {
      return buildChild(constraints);
    }
    return _DraggablePoint(
      onLayerTapped: () => widget.onLayerTapped?.call(layerItem),
      onDragStart: (d) {
        widget.onDragStart?.call(layerItem);
        startingFingerPositionFromObject = d;
      },
      onDragEnd: () {
        widget.onDragEnd?.call(layerItem);
        if (deleteAreaRect.contains(currentFingerPosition)) {
          widget.onDelete?.call();
        }
      },
      onDrag: widget.isFocus
          ? (d, focalPoint) async {
              setState(() {
                objectPosition = Offset(objectPosition.dx + d.dx, objectPosition.dy + d.dy);
                isCenteredHorizontally = _checkIfCentered(objectPosition, size, constraints.maxWidth, Axis.horizontal);
                isCenteredVertically = _checkIfCentered(objectPosition, size, constraints.maxHeight, Axis.vertical);
                // deleteArea에 닿았는지 확인
              });

              currentFingerPosition = startingFingerPositionFromObject + objectPosition;

              if (deleteAreaRect.contains(currentFingerPosition)) {
                if (await Vibration.hasVibrator() ?? false) {
                  Vibration.vibrate(duration: 100);
                }
              }
            }
          : null,
      onScale: widget.isFocus ? (s) => _handleScale(s, constraints) : null,
      onRotate: widget.isFocus
          ? (a) => setState(() {
                angle = a;
              })
          : null,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: 1.0,
            child: buildChild(constraints),
          ),
        ),
      ),
    );
  }

  // 스케일 핸들러
  void _handleScale(double scale, BoxConstraints constraints) {
    log('onScale');
    final updatedSize = Size(
      widget.layerItem.size.width * scale,
      widget.layerItem.size.height * scale,
    );

    final midX = objectPosition.dx + (size.width / 2);
    final midY = objectPosition.dy + (size.height / 2);
    final updatedPosition = Offset(
      midX - (updatedSize.width / 2),
      midY - (updatedSize.height / 2),
    );

    setState(() {
      size = updatedSize;
      objectPosition = updatedPosition;
    });
  }

  // 센터링 검사 메서드 (수평/수직)
  bool _checkIfCentered(Offset position, Size size, double canvasDimen, Axis axis) {
    final center = canvasDimen / 2;
    final widgetCenter = (axis == Axis.vertical ? position.dy : position.dx) + size.width / 2;
    return (center - widgetCenter).abs() < 5;
  }

  Widget buildChild(BoxConstraints constraints) {
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
              style: textEditorStyle.textStyle
                  .copyWith(fontSize: textEditorStyle.textStyle.fontSize! * (size.width / widget.layerItem.size.width)),
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
      case LayerType.background:
        return SizedBox(
          height: size.height,
          width: size.width,
          child: widget.layerItem.object,
        );
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
/*
FractionalTranslation(
                  translation: const Offset(0, 0),
 */