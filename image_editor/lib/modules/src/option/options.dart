import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../src.dart';

part 'add_text.dart';
part 'clip.dart';
part 'color.dart';
part 'draw.dart';
part 'flip.dart';
part 'mix_image.dart';
part 'rotate.dart';
part 'scale.dart';

abstract class IgnoreAble {
  bool get canIgnore;
}

abstract class TransferValue implements IgnoreAble {
  String get key;

  Map<String, Object> get transferValue;
}

abstract class Option implements IgnoreAble, TransferValue {
  const Option();
}

class ImageEditorOption implements IgnoreAble {
  ImageEditorOption();

  OutputFormat outputFormat = OutputFormat.jpeg(95);

  List<Option> get options {
    List<Option> result = [];
    for (final group in groupList) {
      for (final opt in group) {
        result.add(opt);
      }
    }
    return result;
  }

  List<OptionGroup> groupList = [];

  void reset() {
    groupList.clear();
  }

  void addOption(Option option, {bool newGroup = false}) {
    OptionGroup group;
    if (groupList.isEmpty || newGroup) {
      group = OptionGroup();
      groupList.add(group);
    } else {
      group = groupList.last;
    }

    group.addOption(option);
  }

  void addOptions(List<Option> options, {bool newGroup = true}) {
    OptionGroup group;
    if (groupList.isEmpty || newGroup) {
      group = OptionGroup();
      groupList.add(group);
    } else {
      group = groupList.last;
    }

    group.addOptions(options);
  }

  List<Map<String, Object>> toJson() {
    List<Map<String, Object>> result = [];
    for (final option in options) {
      if (option.canIgnore) {
        continue;
      }
      result.add({
        "type": option.key,
        "value": option.transferValue,
      });
    }
    return result;
  }

  @override
  bool get canIgnore {
    for (final opt in options) {
      if (!opt.canIgnore) {
        return false;
      }
    }
    return true;
  }

  String toString() {
    final m = <String, dynamic>{};
    m['options'] = toJson();
    m['fmt'] = outputFormat.toJson();
    return JsonEncoder.withIndent('  ').convert(m);
  }
}

class OptionGroup extends ListBase<Option> implements IgnoreAble {
  @override
  bool get canIgnore {
    for (final option in options) {
      if (!option.canIgnore) {
        return false;
      }
    }
    return true;
  }

  final List<Option> options = [];

  void addOptions(List<Option> optionList) {
    this.options.addAll(optionList);
  }

  void addOption(Option option) {
    this.options.add(option);
  }

  @override
  int get length => options.length;

  @override
  operator [](int index) {
    return options[index];
  }

  @override
  void operator []=(int index, value) {
    options[index] = value;
  }

  @override
  set length(int newLength) {
    options.length = newLength;
  }
}
