import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class CaptureController {
  GlobalKey? key;
  final String _FILE_NAME = 'capture_';
  final double _RATIO = 3;

  CaptureController();

  Future<File?> captureFirstFrame() => _captureFirstFrame();

// 첫 번째 프레임 캡쳐
  Future<File?> _captureFirstFrame() async {
    final directory = await getTemporaryDirectory();
    if (key == null) {
      throw Exception('GlobalKey가 null입니다.'); // 적절한 예외 처리를 위한 예외 발생
    }

    try {
      ui.Image? image = _captureContext(key!);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      Uint8List? byte = byteData?.buffer.asUint8List();

      final imagePath = '${directory.path}/${_FILE_NAME}00.png';

      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(byte!);

      return imageFile;
    } catch (e) {
      // 적절한 오류 처리를 여기에 추가하세요.
      developer.log("첫 번째 프레임 캡처 중 오류 발생: $e");
      return null;
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
}
