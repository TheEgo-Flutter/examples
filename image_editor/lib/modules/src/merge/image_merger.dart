import 'dart:io';
import 'dart:typed_data';

import '../src.dart';

class ImageMerger {
  ImageMerger._();

  static Future<Uint8List?> mergeToMemory({required ImageMergeOption option}) {
    return NativeChannel.channel.invokeMethod('mergeToMemory', {
      'option': option.toJson(),
    });
  }

  static Future<File?> mergeToFile({required ImageMergeOption option}) {
    return NativeChannel.channel.invokeMethod('mergeToFile', {
      'option': option.toJson(),
    });
  }
}
