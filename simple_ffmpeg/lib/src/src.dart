export 'renderer.dart';
export 'video_encoder.dart';

const int DURATION = 1;
const int TOTAL_FRAME = DURATION * 60;
const double RATIO = 3.0;
const String FILE_NAME = 'capture_';
const double SIZE = 200.0;
const String SCALE = '${SIZE * RATIO}:${SIZE * RATIO}';
