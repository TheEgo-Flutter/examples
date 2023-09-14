import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

const String _FILE_NAME = 'capture_';
const double _RATIO = 3;

class FFMpegController {
  GlobalKey? key;

  String get SCALE => '${size.width * _RATIO}:${size.height * _RATIO}';

  int get TOTAL_FRAME => fps * duration.inSeconds;

  Size get size => _size;
  Size _size = Size.zero;
  set size(Size value) => _size = value;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;
  set duration(Duration value) => _duration = value;

  int get fps => _fps;
  int _fps = 0;
  set fps(int value) => _fps = value;

  FFMpegController();

  // Renderer 기능
  Future<List<String>> captureAnimation({required AnimationController controller, required int framerate}) async {
    List<String> capturedImages = [];
    final directory = await getTemporaryDirectory();
    if (key == null) {
      return capturedImages;
    }
    final renderObject = key!.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    size = renderObject?.size ?? Size.zero;
    fps = framerate;
    duration = controller.duration ?? Duration.zero;
    Duration captureDuration = duration ~/ TOTAL_FRAME;
    for (int i = 0; i < TOTAL_FRAME; i++) {
      controller.value = i / (TOTAL_FRAME - 1);
      Uint8List? byte = await Future<Uint8List?>.delayed(captureDuration, () async {
        try {
          ui.Image? image = _captureContext(key!);

          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return byteData?.buffer.asUint8List();
        } catch (e) {
          throw Exception("Capture Failed: $e");
        }
      });

      if (byte == null) continue;
      final imagePath = '${directory.path}/$_FILE_NAME${(i + 1).toString()}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byte);
      capturedImages.add(imagePath); // 경로를 리스트에 추가
    }
    return capturedImages;
  }

  ui.Image _captureContext(GlobalKey key) {
    try {
      final renderObject = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject == null) {
        throw Exception(
          "Capturing frame context unsuccessful as context is null."
          " Trying next frame.",
        );
      }
      return renderObject.toImageSync(pixelRatio: _RATIO);
    } catch (e) {
      throw Exception(
        "Unknown error while capturing frame context. Trying next frame.",
      );
    }
  }

  Future<File?> fileToVideo({required AnimationController controller, required int framerate}) async {
    final completer = Completer<bool>();
    final directory = await getTemporaryDirectory();
    if (Platform.isAndroid || Platform.isIOS) {
      if (await FFmpegKitConfig.getFFmpegVersion() == null) {
        await FFmpegKitConfig.init();
      }
    }
    await captureAnimation(controller: controller, framerate: framerate);
    final videoFile = await _getVideoFile();
    await _deleteFile(videoFile);
    final ffmpegCommand = _generateEncodeVideoScript(videoFile.path, directory);

    await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
      final state = FFmpegKitConfig.sessionStateToString(await session.getState());
      final failStackTrace = await session.getFailStackTrace();
      final duration = await session.getDuration();
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        developer.log("성공: $state");
        completer.complete(true);
      } else {
        developer.log("실패: $state, $failStackTrace");
        completer.completeError('변환 실패');
      }
    }, (_log) => developer.log(_log.getMessage()), (statistics) {});

    await completer.future; // completer가 완료될 때까지 기다림

    return videoFile;
  }

  Future<File> _getVideoFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return File("${documentsDirectory.path}/encoding_video.mp4");
  }

  Future<void> _deleteFile(File file) async {
    await file.exists().then((exists) {
      if (exists) {
        try {
          file.delete();
        } on Exception catch (e) {
          developer.log("Exception occurred while deleting the file. $e");
        }
      }
    });
  }

  String _generateEncodeVideoScript(
    String videoFilePath,
    Directory directory,
  ) {
    print(
        "-framerate $fps -i '${directory.path}/$_FILE_NAME%d.png' -vf: scale=$SCALE -b:v 3000k -c:a pcm_s16le -b:a 192k $videoFilePath");
    return "-framerate $fps -i '${directory.path}/$_FILE_NAME%d.png' -b:v 3000k -c:a pcm_s16le -b:a 192k  $videoFilePath";
  }
}
