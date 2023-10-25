part of 'src.dart';

const String _FILE_NAME = 'capture_';
const double _RATIO = 3;

class FFMpegController {
  GlobalKey? key;
  String get SCALE => '${(size.width * _RATIO).toInt()}:${(size.height * _RATIO).toInt()}';
  Size get size => _size;
  Size _size = Size.zero;
  set size(Size value) => _size = value;

  String firstFrame = '';

  FFMpegController();

  Future<File?> captureFirstFrame() => _captureFirstFrame();

  Future<File?> encodingVideo({int totalFrame = 20, Duration totalDuration = const Duration(seconds: 2)}) async {
    List<File> capturedFrames = [];
    try {
      capturedFrames = await _captureFrames(totalFrame: totalFrame, totalDuration: totalDuration);
    } catch (e) {
      developer.log("프레임 캡처 중 에러 발생: $e");
      return null;
    }
    return await _convertFramesToVideo(capturedFrames: capturedFrames, totalDuration: totalDuration);
  }

  Future<List<File>> _captureFrames({required int totalFrame, required Duration totalDuration}) async {
    await _clearTemporaryFiles();
    List<File> capturedFrames = [];

    try {
      File? file = await _captureFirstFrame();
      if (file != null && file.existsSync()) {
        capturedFrames.add(file);
      }
    } catch (e) {
      rethrow;
    }
    if (totalFrame > 1) {
      List<File>? files = await _captureRemainingFrames(totalFrame: totalFrame, totalDuration: totalDuration);
      if (files != null) {
        capturedFrames.addAll(files);
      }
    }

    return capturedFrames;
  }

// 첫 번째 프레임 캡쳐
  Future<File?> _captureFirstFrame() async {
    final directory = await getTemporaryDirectory();
    if (key == null) {
      throw Exception('GlobalKey가 null입니다.'); // 적절한 예외 처리를 위한 예외 발생
    }

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

      return imageFile;
    } catch (e) {
      // 적절한 오류 처리를 여기에 추가하세요.
      developer.log("첫 번째 프레임 캡처 중 오류 발생: $e");
      return null;
    }
  }

// 이후 프레임 캡쳐
  Future<List<File>?> _captureRemainingFrames({required int totalFrame, required Duration totalDuration}) async {
    final directory = await getTemporaryDirectory();
    final List<File> capturedFrames = [];
    Duration delay = totalDuration ~/ totalFrame;
    for (int i = 1; i < totalFrame; i++) {
      Uint8List? byte = await Future<Uint8List?>.delayed(delay, () async {
        try {
          ui.Image? image = _captureContext(key!);

          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();

          return byteData?.buffer.asUint8List();
        } catch (e) {
          // 특정 프레임 캡처 중 발생하는 예외를 처리합니다.
          developer.log("프레임 $i 캡처 중 오류 발생: $e");
          return null;
        }
      });

      if (byte == null) continue; // 오류로 인해 byte가 null인 경우, 다음 프레임 캡처로 건너뜁니다.

      final imagePath = '${directory.path}/$_FILE_NAME${i.toString().padLeft(2, '0')}.png';

      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byte);
      capturedFrames.add(imageFile);
    }

    return capturedFrames.isNotEmpty ? capturedFrames : null;
  }

  /// 캡처한 프레임을 FFmpeg를 사용하여 비디오로 변환합니다.
  Future<File?> _convertFramesToVideo({required List<File> capturedFrames, required Duration totalDuration}) async {
    final completer = Completer<bool>();
    final directory = await getTemporaryDirectory();

    if (Platform.isAndroid || Platform.isIOS) {
      if (await FFmpegKitConfig.getFFmpegVersion() == null) {
        await FFmpegKitConfig.init();
      }
    }

    final videoFile = await _generateVideoFilePath();
    await _deleteFile(videoFile);

    final ffmpegCommand = _generateEncodeVideoScript(capturedFrames.length, totalDuration, videoFile.path, directory);
    await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
      final state = FFmpegKitConfig.sessionStateToString(await session.getState());
      final failStackTrace = await session.getFailStackTrace();
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        completer.complete(true);
      } else {
        completer.completeError('변환 실패');
      }
    }, (log) => developer.log(log.getMessage()), (statistics) {});

    await completer.future;
    return videoFile;
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

  Future<void> _clearTemporaryFiles() async {
    final directory = await getTemporaryDirectory();
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
  }

  /// 지정된 파일이 존재하는 경우 삭제합니다.
  Future<void> _deleteFile(File file) async {
    bool exists = await file.exists();
    if (exists) {
      try {
        await file.delete();
      } catch (e) {
        developer.log("Failed to delete file: ${file.path}, error: $e");
      }
    }
  }

  /// 인코딩된 비디오의 파일 경로를 생성합니다.
  Future<File> _generateVideoFilePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return File("${documentsDirectory.path}/encoding_video.mp4");
  }

  String _generateEncodeVideoScript(int frames, Duration duration, String videoFilePath, Directory directory) {
    int framerate = frames ~/ duration.inSeconds;
    String command = '';
    if (frames <= 1) {
      command =
          "-loop 1 -i '${directory.path}/${_FILE_NAME}00.png' -t 2 -c:v h264 -b:v 3000k  -vf scale=$SCALE $videoFilePath";
    } else {
      command =
          "-framerate $framerate -i '${directory.path}/$_FILE_NAME%02d.png' -t ${duration.inSeconds} -c:v h264 -b:v 3000k -vf scale=$SCALE $videoFilePath";

      // "-framerate $framerate -i '${directory.path}/$_FILE_NAME%02d.png' -t ${duration.inSeconds} -b:v 3000k -vf scale=$SCALE $videoFilePath";
    }
    developer.log(command);
    return command;
  }
}
