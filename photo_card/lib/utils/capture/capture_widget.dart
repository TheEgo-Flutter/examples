import 'package:flutter/material.dart';
import 'package:photo_card/utils/capture/capture_controller.dart';

class CaptureWidget extends StatefulWidget {
  final CaptureController? controller;
  final Widget child;

  const CaptureWidget({super.key, this.controller, required this.child});

  @override
  State<CaptureWidget> createState() => _CaptureWidgetState();
}

class _CaptureWidgetState extends State<CaptureWidget> with WidgetsBindingObserver {
  final GlobalKey renderKey = GlobalKey();
  bool hasAttached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    attachToController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: renderKey,
      child: widget.child,
    );
  }

  void attachToController() {
    if (!hasAttached && widget.controller != null) {
      widget.controller?.key = renderKey;
      hasAttached = true;
    }
  }
}
