import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

Future<List<ImageProvider>> loadImageProvider(List<String> assetPaths) async {
  List<ImageProvider> stickers = [];
  for (String path in assetPaths) {
    try {
      final ByteData data = await rootBundle.load('assets/$path');
      final Uint8List bytes = data.buffer.asUint8List();
      stickers.add(MemoryImage(bytes));
    } catch (e) {
      log("이미지를 불러오는 도중 오류가 발생했습니다: $e");
    }
  }
  return stickers;
}

Future<List<Uint8List>> loadStickers(List<String> assetPaths) async {
  List<Uint8List> stickers = [];
  for (String path in assetPaths) {
    try {
      final ByteData data = await rootBundle.load('assets/$path');
      final List<int> bytes = data.buffer.asUint8List();
      stickers.add(Uint8List.fromList(bytes));
    } catch (e) {
      log("이미지를 불러오는 도중 오류가 발생했습니다: $e");
    }
  }
  return stickers;
}

Future<ByteData> fetchFont(String url) async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    return ByteData.view(response.bodyBytes.buffer);
  } else {
    throw Exception('Failed to load font');
  }
}

var fontUrls = {
  'GmarketSansBold': 'https://dingdongu.s3.ap-northeast-2.amazonaws.com/dev/fonts/gmarket/GmarketSansBold.otf',
  'GmarketSansLight': 'https://dingdongu.s3.ap-northeast-2.amazonaws.com/dev/fonts/gmarket/GmarketSansLight.otf',
  'GmarketSansMedium': 'https://dingdongu.s3.ap-northeast-2.amazonaws.com/dev/fonts/gmarket/GmarketSansMedium.otf',
  'Cafe24Ssurround':
      'https://dingdongu.s3.ap-northeast-2.amazonaws.com/dev/fonts/cafe24s-surround/Cafe24Ssurround-v2.0.ttf',
  'MaruBuri-Bold': 'https://dingdongu.s3.ap-northeast-2.amazonaws.com/dev/fonts/maruburi/MaruBuri-Bold.ttf',
  'Montserrat': 'https://github.com/google/fonts/raw/main/ofl/meddon/Meddon.ttf',
};
List<String> stickers = [
  'stickers/sticker_01.png',
  'stickers/sticker_02.png',
  'stickers/sticker_03.png',
  'stickers/sticker_04.png',
  'stickers/sticker_05.png',
  'stickers/sticker_06.png',
  'stickers/sticker_07.png',
  'stickers/sticker_08.png',
  'stickers/sticker_09.png',
  'stickers/sticker_10.png',
  'stickers/sticker_11.png',
  'stickers/sticker_12.json',
  'stickers/sticker_13.png',
  'stickers/sticker_14.png',
  'stickers/sticker_15.png',
  'stickers/sticker_16.png',
  'stickers/sticker_17.png',
  'stickers/sticker_18.png',
  'stickers/sticker_19.png',
  'stickers/sticker_20.png',
  'stickers/sticker_21.png',
  'stickers/sticker_22.png',
  'stickers/sticker_23.png',
  'stickers/sticker_24.png',
  'stickers/sticker_25.png',
  'stickers/sticker_26.png',
  'stickers/sticker_27.png',
  'stickers/sticker_28.png',
];
List<String> frames = [
  "frames/frame01.png",
  "frames/frame02.png",
  "frames/frame_163.png",
  "frames/frame_164.png",
  "frames/frame_165.png",
  "frames/frame_166.png",
  "frames/frame_167.png",
  "frames/frame_168.png",
];
List<String> backgrounds = [
  "backgrounds/bg_165.png",
  "backgrounds/bg_166.png",
  "backgrounds/bg_168.png",
  "backgrounds/bg_169.png",
  "backgrounds/bg_170.png",
  "backgrounds/bg_172.png",
  "backgrounds/bg_173.png",
  "backgrounds/bg_174.png",
  "backgrounds/bg_175.png",
];
