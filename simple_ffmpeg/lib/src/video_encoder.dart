import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoEncoder {
  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  final String fileName;
  final int totalFrame;
  final int duration;
  final String scale;
  VideoEncoder({
    required this.fileName,
    required this.scale,
    required this.totalFrame,
    required this.duration,
  });

  Future<File> getVideoFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return File("${documentsDirectory.path}/video.mp4");
  }

  Future<File?> fileToVideo(List<String> imagePaths) async {
    final completer = Completer<bool>();
    final directory = await getTemporaryDirectory();
    if (Platform.isAndroid || Platform.isIOS) {
      if (await FFmpegKitConfig.getFFmpegVersion() == null) {
        await FFmpegKitConfig.init();
      }
    }

    final videoFile = await getVideoFile();
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
    return "-framerate $totalFrame/$duration -i '${directory.path}/$fileName%d.png' -vf: scale=$scale -q 1 -b:v 2M -maxrate 2M -bufsize 1M  $videoFilePath";
  }
}
