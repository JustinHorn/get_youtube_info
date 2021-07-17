import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_youtube_info/get_youtube_info.dart';

expectOk(dynamic x) => expect(nodeIsTruthy(x), true);
expectNotOk(dynamic x) => expect(nodeIsTruthy(x), false);

Future<String> getFileAsString(String path) async {
  final fileString = await File(path).readAsString();
  return fileString;
}

Future<Map<String, dynamic>> getFileAsMap(String path) async {
  final fileString = await File(path).readAsString();
  final Map<String, dynamic> html5player = jsonDecode(fileString);
  return html5player;
}

Future<dynamic> getFileAsMapOrList(String path) async {
  final fileString = await File(path).readAsString();
  return jsonDecode(fileString);
}
