import 'dart:async';
import 'dart:io';

// import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nock/nock.dart';

import './nock.dart';
import 'helper.dart';

main() async {
  // var sDart = await File('./testA.txt').readAsString();
  // var sNode = await File('./testNode.txt').readAsString();

  // var sDartlength = sDart.length;
  // int failures = 0;
  // for (var i = 0; i < sDartlength; i += 100) {
  //   var dart_substring = sDart.substring(i, i + 100);
  //   var node_substring = sNode.substring(i, i + 100);
  //   if (dart_substring != node_substring) {
  //     print('failure: ${++failures}');
  //     print(dart_substring);
  //     print(node_substring);
  //     print(i);
  //   }

  nock.init();

  var x =
      'https://www.youtube.com/s/player/62f90c99/player_ias.vflset/en_US/base.js';
  final id = '_HSylqgVYQI';

  final scope = await nockFunction(id, 'live-now');

  var response = await http.get(Uri.parse(x));

  print(response);

  print(response.statusCode);

  // response = await http.get(Uri.parse(x), headers: {'abc': 'fuckOff'});

  // print(response);

  // print(response.statusCode);

  // response = await http.get(Uri.parse(x), headers: {'abc': 'fuckOff'});

  // print(response);

  // print(response.statusCode);

  scope.done();
}
