import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoContainer extends StatefulWidget {
  const VideoContainer({super.key, required this.videoController});
  final VideoPlayerController videoController;
  @override
  State<VideoContainer> createState() => _VideoContainerState();
}

class _VideoContainerState extends State<VideoContainer> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 52,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: widget.videoController.value.isInitialized ? VideoPlayer(widget.videoController) : shimmerEffect(),
      ),
    );
  }

  Widget shimmerEffect() {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (_, double opacity, __) {
        return Container(
          color: Colors.white.withOpacity(opacity),
        );
      },
      onEnd: () {
        setState(() {});
      },
    );
  }
}
