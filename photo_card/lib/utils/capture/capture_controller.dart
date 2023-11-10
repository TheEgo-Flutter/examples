import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class CaptureController {
  GlobalKey? key;
  final String _FILE_NAME = 'capture_';
  final double _RATIO = 3;

  CaptureController();

  Future<File?> captureFirstFrame() async {
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

  Future<ui.Image> mergeImages(ui.Image image, ui.Image background) async {
    // image2의 width와 height 중 큰 쪽을 기준으로 1:1 비율의 캔버스를 만듭니다.
    final double _max = max(background.width, background.height).toDouble();
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _max, _max));

    // 배경 이미지인 image2를 1:1 비율로 중앙에 그립니다.

    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, _max, _max),
      image: background,
      fit: BoxFit.fill,
    );

    // image1을 중앙에 위치시키고 상하좌우에 16의 패딩을 추가합니다.
    const double padding = 16.0;
    final Size paddedSize = Size(
      _max - padding * 2, // 좌우 패딩을 고려한 너비
      _max - padding * 2, // 상하 패딩을 고려한 높이
    );
    final FittedSizes fittedSizes = applyBoxFit(
      BoxFit.contain,
      Size(image.width.toDouble(), image.height.toDouble()),
      paddedSize,
    );
    final Rect imageRect = Alignment.center.inscribe(
      fittedSizes.destination,
      Rect.fromCenter(
        center: Offset(_max / 2, _max / 2),
        width: paddedSize.width,
        height: paddedSize.height,
      ),
    );
    paintImage(
      canvas: canvas,
      rect: imageRect,
      image: image,
      fit: BoxFit.contain,
    );

    // Canvas에서 Picture로 변환합니다.
    final ui.Picture picture = recorder.endRecording();

    // Picture를 Image로 변환합니다.
    final ui.Image mergedImage = await picture.toImage(_max.toInt(), _max.toInt());

    return mergedImage;
  }

// 이미지를 ByteData로 변환하는 함수
  Future<Uint8List?> convertImageToByteData(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
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

  Future<File> mergeImagesFromFileAndProvider(File imageFile, ImageProvider provider) async {
    final ui.Image firstImage = await getImageFromFile(imageFile);
    final ui.Image backgroundImage = await getImageFromProvider(provider);

    final ui.Image mergedImage = await mergeImages(firstImage, backgroundImage);
    final Uint8List? mergedImageBytes = await convertImageToByteData(mergedImage);

    final directory = await getTemporaryDirectory();
    final mergedImagePath = '${directory.path}/merged_image.png';
    final mergedImageFile = File(mergedImagePath);
    await mergedImageFile.writeAsBytes(mergedImageBytes!);

    return mergedImageFile;
  }

  Future<ui.Image> getImageFromFile(File imageFile) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<ui.Image> getImageFromProvider(ImageProvider provider) async {
    var completer = Completer<ImageInfo>();
    provider.resolve(const ImageConfiguration()).addListener(ImageStreamListener((info, _) {
      completer.complete(info);
    }));
    ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
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
