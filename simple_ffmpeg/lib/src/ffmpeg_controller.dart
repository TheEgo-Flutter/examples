part of 'src.dart';

/// The prefix used for temporary files created during frame capture.
const String _FILE_NAME = 'capture_';

/// The pixel ratio used for capturing frames.
const double _RATIO = 3;

/// A controller for capturing frames and converting them to video using FFmpeg.
class FFMpegController {
  GlobalKey? key;
  int _actualFrameCount = 0;

  /// The scale used for capturing frames.
  String get SCALE => '${(size.width * _RATIO).toInt()}:${(size.height * _RATIO).toInt()}';

  /// The size of the captured frames.
  Size get size => _size;
  Size _size = Size.zero;
  set size(Size value) => _size = value;

  /// The total duration of the captured video.
  Duration get totalDuration => _totalDuration;
  Duration _totalDuration = const Duration(seconds: 2);
  set totalDuration(Duration value) => _totalDuration = value;

  /// The delay between each captured frame.
  Duration get frameDelay => _frameDelay;
  Duration _frameDelay = const Duration(milliseconds: 1000 ~/ 30);
  set frameDelay(Duration value) => _frameDelay = value;

  /// The total number of frames to capture.
  int get totalFrame => _totalFrame;
  int _totalFrame = 60;
  set totalFrame(int value) => _totalFrame = value;

  /// The frames per second (FPS) of the captured video.
  int get fps => _fps;
  int _fps = 30; // 기본값으로 설정
  set fps(int value) => _fps = value;

  /// The path to the first captured frame.
  String get firstFrame => _firstFrame;
  String _firstFrame = '';
  set firstFrame(String value) => _firstFrame = value;

  /// Creates a new instance of [FFMpegController].
  FFMpegController();

  /// Captures frames from the current context and saves them as image files.
  Future<void> _captureFrames() async {
    final directory = await getTemporaryDirectory();

    // Delete all files in the temporary directory with the _FILE_NAME prefix.
    final files = directory.listSync();

    for (var file in files) {
      if (file is File && file.path.contains(_FILE_NAME)) {
        try {
          await file.delete();
        } catch (e) {
          developer.log("Failed to delete file: ${file.path}, error: $e");
        }
      }
    }

    if (key == null) {
      return;
    }

    firstFrame = '';
    _actualFrameCount = 0;

    final renderObject = key!.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    size = renderObject?.size ?? Size.zero;

    try {
      ui.Image? image = _captureContext(key!);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      Uint8List? byte = byteData?.buffer.asUint8List();

      final imagePath = '${directory.path}/${_FILE_NAME}00.png';
      firstFrame = imagePath;

      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byte!);
      _actualFrameCount++;
    } catch (e) {
      return;
    }

    for (int i = 1; i < totalFrame; i++) {
      Uint8List? byte = await Future<Uint8List?>.delayed(Duration.zero, () async {
        try {
          ui.Image? image = _captureContext(key!);

          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          _actualFrameCount++;
          return byteData?.buffer.asUint8List();
        } catch (e) {}
        return null;
      });

      if (byte == null) continue;

      final imagePath = '${directory.path}/$_FILE_NAME${i.toString().padLeft(2, '0')}.png';

      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byte);
    }
  }

  /// 캡처한 프레임을 FFmpeg를 사용하여 비디오로 변환합니다.
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
        completer.complete(true);
      } else {
        completer.completeError('변환 실패');
      }
    }, (_log) => developer.log(_log.getMessage()), (statistics) {});

    await completer.future;
    return videoFile;
  }

  /// 지정된 기간 동안 프레임을 캡처하고 비디오로 변환합니다.
  ///
  /// [totalFrames] 매개변수는 캡처할 총 프레임 수를 지정합니다.
  /// [totalDuration] 또는 [frameDelay] 매개변수 중 하나를 제공해야 합니다.
  /// 둘 다 제공하는 경우 [frameDelay] 매개변수가 우선합니다.
  Future<File?> captureDurationToVideo(
      {required int totalFrames, Duration? totalDuration, Duration? frameDelay}) async {
    if (totalDuration == null && frameDelay == null) {
      throw ArgumentError('totalDuration 또는 frameDelay 중 하나를 제공해야 합니다.');
    }
    totalFrame = totalFrames;
    _setDuration(frameDelay, totalDuration);

    await _captureFrames();
    return await _convertFramesToVideo();
  }

  /// 제공된 매개변수를 기반으로 캡처된 비디오의 길이를 설정합니다.
  void _setDuration(Duration? frameDelay, Duration? totalDuration) {
    if (frameDelay != null) {
      this.frameDelay = frameDelay;
      this.totalDuration = Duration(milliseconds: frameDelay.inMilliseconds * totalFrame);
    } else if (totalDuration != null) {
      this.totalDuration = totalDuration;
      this.frameDelay = Duration(milliseconds: totalDuration.inMilliseconds ~/ totalFrame);
    }
  }

  /// 현재 컨텍스트를 이미지로 캡처합니다.
  ui.Image _captureContext(GlobalKey key) {
    try {
      final renderObject = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject == null) {
        throw Exception(
          "컨텍스트를 캡처하는 데 실패했습니다. 다음 프레임을 시도합니다.",
        );
      }
      return renderObject.toImageSync(pixelRatio: _RATIO);
    } catch (e) {
      throw Exception(
        "프레임 컨텍스트를 캡처하는 동안 알 수 없는 오류가 발생했습니다. 다음 프레임을 시도합니다.",
      );
    }
  }

  /// 인코딩된 비디오의 파일 경로를 생성합니다.
  Future<File> _generateVideoFilePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return File("${documentsDirectory.path}/encoding_video.mp4");
  }

  /// 지정된 파일이 존재하는 경우 삭제합니다.
  Future<void> _deleteFile(File file) async {
    bool exists = await file.exists();
    if (exists) {
      try {
        await file.delete();
      } on Exception catch (e) {}
    }
  }

  String _generateEncodeVideoScript(String videoFilePath, Directory directory) {
    int calculatedFramerate = _actualFrameCount ~/ 2;
    developer.log(_actualFrameCount.toString());
    String command = '';
    if (_actualFrameCount <= 1 || totalDuration == Duration.zero) {
      command = "-loop 1 -i '${directory.path}/${_FILE_NAME}00.png' -t 2 -b:v 3000k  -vf scale=$SCALE $videoFilePath";
    } else {
      command =
          "-framerate $calculatedFramerate -i '${directory.path}/$_FILE_NAME%02d.png' -t 2 -b:v 3000k -vf scale=$SCALE $videoFilePath";
    }
    developer.log(command);
    return command;
  }
}
