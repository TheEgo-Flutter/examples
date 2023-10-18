part of 'src.dart';

class FFmpegWidget extends StatefulWidget {
  final FFMpegController? controller;
  final Widget child;

  const FFmpegWidget({super.key, this.controller, required this.child});

  @override
  State<FFmpegWidget> createState() => _FFmpegWidgetState();
}

class _FFmpegWidgetState extends State<FFmpegWidget> with WidgetsBindingObserver {
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
