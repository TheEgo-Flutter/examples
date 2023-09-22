part of 'src.dart';

const String _FILE_NAME = 'capture_';
const double _RATIO = 3;

class FFMpegController {
  GlobalKey? key;

  String get SCALE => '${size.width * _RATIO}:${size.height * _RATIO}';
  int get TOTAL_FRAME => (fps * duration.inSeconds).toInt();
  Duration get captureDuration => Duration(milliseconds: (1000 / fps).round());

  Size get size => _size;
  Size _size = Size.zero;
  set size(Size value) => _size = value;

  Duration get duration => _duration;
  Duration _duration = Duration.zero;
  set duration(Duration value) => _duration = value;

  int get fps => _fps;
  int _fps = 60;
  set fps(int value) => _fps = value;

  String get firstFrame => _firstFrame;
  String _firstFrame = '';
  set firstFrame(String value) => _firstFrame = value;

  FFMpegController();
  Future<void> _captureFrames({AnimationController? controller}) async {
    final directory = await getTemporaryDirectory();

    // 임시 디렉터리에서 _FILE_NAME 접미사를 가진 모든 파일 삭제
    final files = directory.listSync();
    for (var file in files) {
      if (file is File && file.path.contains(_FILE_NAME)) {
        try {
          await file.delete();
        } catch (e) {
          developer.log("파일 삭제 실패: ${file.path}, 오류: $e");
        }
      }
    }

    if (key == null) {
      return;
    }

    // firstFrame 초기화
    firstFrame = '';

    final renderObject = key!.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    size = renderObject?.size ?? Size.zero;

    for (int i = 0; i < TOTAL_FRAME; i++) {
      if (controller != null) {
        controller.value = i / (TOTAL_FRAME - 1);
      }
      Uint8List? byte = await Future<Uint8List?>.delayed(captureDuration, () async {
        try {
          ui.Image? image = _captureContext(key!);

          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return byteData?.buffer.asUint8List();
        } catch (e) {
          developer.log("캡처 실패: $e");
        }
        return null;
      });

      // byte가 null이 아니고 firstFrame이 비어있을 경우 firstFrame에 저장

      if (byte == null) continue;

      final imagePath = '${directory.path}/$_FILE_NAME${(i + 1).toString()}.png';
      if (firstFrame.isEmpty) {
        firstFrame = imagePath;
      }
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byte);
    }
  }

  Future<File?> _convertFramesToVideo() async {
    final completer = Completer<bool>();
    final directory = await getTemporaryDirectory();

    if (Platform.isAndroid || Platform.isIOS) {
      if (await FFmpegKitConfig.getFFmpegVersion() == null) {
        await FFmpegKitConfig.init();
      }
    }

    final videoFile = await _generateVideoFilePath();
    await _deleteFile(videoFile);
    final ffmpegCommand = _generateEncodeVideoScript(videoFile.path, directory);

    await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
      final state = FFmpegKitConfig.sessionStateToString(await session.getState());
      final failStackTrace = await session.getFailStackTrace();
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

  Future<File?> animationToVideo({required AnimationController controller, required int framerate}) async {
    fps = framerate;
    duration = controller.duration ?? Duration.zero;
    await _captureFrames(controller: controller);
    return await _convertFramesToVideo();
  }

  Future<File?> captureDurationToVideo({required int framerate}) async {
    fps = framerate;
    await _captureFrames();
    return await _convertFramesToVideo();
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

  Future<File> _generateVideoFilePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return File("${documentsDirectory.path}/encoding_video.mp4");
  }

  Future<void> _deleteFile(File file) async {
    bool exists = await file.exists();
    if (exists) {
      try {
        await file.delete();
      } on Exception catch (e) {
        developer.log("Exception occurred while deleting the file. $e");
      }
    }
  }

  String _generateEncodeVideoScript(
    String videoFilePath,
    Directory directory,
  ) {
    print("FPS: $fps\nDuration: $duration\nTotal Frames: $TOTAL_FRAME\nCapture Duration: $captureDuration\n");
    String command = '';
    if (Platform.isAndroid) {
      command = "-framerate $fps -i '${directory.path}/$_FILE_NAME%d.png' -b:v 3000k $videoFilePath";
    } else {
      command = "-framerate $fps -i '${directory.path}/$_FILE_NAME%d.png' -c:v h264 -b:v 3000k $videoFilePath";
    }
    return command;
  }
}
