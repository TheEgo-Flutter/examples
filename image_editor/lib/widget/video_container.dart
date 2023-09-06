import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoContainer extends StatefulWidget {
  const VideoContainer({super.key});

  @override
  State<VideoContainer> createState() => _VideoContainerState();
}

class _VideoContainerState extends State<VideoContainer> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
        Uri.parse('https://github.com/the-ego/samples/raw/main/assets/video/button.mp4'))
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(true);
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 52,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: shimmerEffect(),
      ),
    );
  }

  Widget shimmerEffect() {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (_, double opacity, __) {
        return Container(
          color: Colors.grey.withOpacity(opacity),
        );
      },
      onEnd: () {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
