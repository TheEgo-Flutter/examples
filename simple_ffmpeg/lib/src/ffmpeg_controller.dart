part of 'src.dart';

const String _FILE_NAME = 'capture_';
const double _RATIO = 3;

class FFMpegController {
  GlobalKey? key;

  String get SCALE => '${size.width * _RATIO}:${size.height * _RATIO}';

  Size get size => _size;
  Size _size = Size.zero;
  set size(Size value) => _size = value;

  Duration get totalDuration => _totalDuration;
  Duration _totalDuration = const Duration(seconds: 2);
  set totalDuration(Duration value) => _totalDuration = value;

  Duration get frameDelay => _frameDelay;
  Duration _frameDelay = const Duration(milliseconds: 1000 ~/ 30);
  set frameDelay(Duration value) => _frameDelay = value;

  int get totalFrame => _totalFrame;
  int _totalFrame = 60;
  set totalFrame(int value) => _totalFrame = value;

  int get fps => _fps;
  int _fps = 30; // 기본값으로 설정
  set fps(int value) => _fps = value;

  String get firstFrame => _firstFrame;
  String _firstFrame = '';
  set firstFrame(String value) => _firstFrame = value;

  FFMpegController();

  Future<void> _captureFrames() async {
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

    for (int i = 0; i < totalFrame; i++) {
      Uint8List? byte = await Future<Uint8List?>.delayed(frameDelay, () async {
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

  Future<File?> captureDurationToVideo(
      {required int totalFrames, Duration? totalDuration, Duration? frameDelay}) async {
    // totalDuration과 frameDelay 둘 다 제공되지 않았을 경우
    if (totalDuration == null && frameDelay == null) {
      throw ArgumentError('totalDuration 또는 frameDelay 중 하나는 반드시 제공되어야 합니다.');
    }
    totalFrame = totalFrames;
    _setDuration(frameDelay, totalDuration);

    // 프레임 캡처 및 비디오 변환
    await _captureFrames();
    return await _convertFramesToVideo();
  }

  void _setDuration(Duration? frameDelay, Duration? totalDuration) {
    if (frameDelay != null) {
      this.frameDelay = frameDelay; // 사용자가 제공한 frameDelay 사용
      this.totalDuration =
          Duration(milliseconds: frameDelay.inMilliseconds * totalFrame); //totalFrame으로 totalDuration 계산
    } else if (totalDuration != null) {
      this.totalDuration = totalDuration; // 사용자가 제공한 totalDuration 사용
      this.frameDelay = Duration(milliseconds: totalDuration.inMilliseconds ~/ totalFrame); //totalFrame으로 frameDelay 계산
    }
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

  String _generateEncodeVideoScript(String videoFilePath, Directory directory) {
    // 총 재생 시간과 총 프레임 수에 따라 프레임레이트를 계산합니다.
    double calculatedFramerate = totalFrame / totalDuration.inSeconds;

    String command = '';
    // 기존에 fps 대신 계산된 프레임레이트를 사용합니다.
    command = "-framerate $calculatedFramerate -i '${directory.path}/$_FILE_NAME%d.png' -b:v 3000k $videoFilePath";
    // 다른 플랫폼 설정이 주석 처리되어 있으므로 필요한 경우 이 부분도 적절히 조정할 수 있습니다.

    return command;
  }
}
