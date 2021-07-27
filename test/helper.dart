import 'dart:convert';
import 'dart:io';

bool helper_nodeIsTruthy(dynamic value) =>
    value != 0 && value != '' && value != false && value != null;

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
