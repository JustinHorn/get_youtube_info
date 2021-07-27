import 'dart:async';
import 'dart:io';

import 'package:nock/nock.dart';

import 'helper.dart';

bool nock_nodeIsTruthy(dynamic value) =>
    value != 0 && value != '' && value != false && value != null;

const YT_HOST = 'https://www.youtube.com';
const MANIFEST_HOST = 'https://manifest.googlevideo.com';
const M3U8_HOST = 'https://manifest.googlevideo.com';
const EMBED_PATH = '/embed/';
const INFO_PATH = '/get_video_info?';

Future<NockFunctionReturn> nockFunction(id, type, {opts}) async {
  nock.init();

  if (opts == null) opts = {};
  List<Interceptor> scopes = [];
  var folder = './test/files/videos/$type';
  var existingFiles = await fileNames(folder);
  var existingFilesSet = Set.from(existingFiles);
  final playerfile =
      RegExp(r'((?:html5)?player[-_][a-zA-Z0-9\-_.]+)(?:\.js|/)');

  opts = {
    'watchJson': existingFilesSet.contains('watch.json'),
    'watchHtml': existingFilesSet.contains('watch.html'),
    'dashmpd': existingFilesSet.contains('dash-manifest.xml'),
    'm3u8': existingFilesSet.contains('hls-manifest.m3u8'),
    'player': existingFiles.where((key) => playerfile.hasMatch(key)).length > 0,
    'embed': existingFilesSet.contains('embed.html'),
    'get_video_info': existingFilesSet.contains('get_video_info'),
    ...opts
  };

  addScope(String host, testOptions, nockOptions) async {
    if (testOptions is List && testOptions[0] is List) {
      List<Future> futures = [];
      testOptions.forEach(
          (testOption) => futures.add(addScope(host, testOption, nockOptions)));
      await Future.wait(futures);
      return;
    }
    var scope = nock(host);
    if (nock_nodeIsTruthy(nockOptions['filteringPath'])) {
      /// TODO: implement filtertinPath!!!
      // print(nockOptions['filteringPath']);
      // scopeInterceptor = filteringPath(
      //     nockOptions['filteringPath'].uri,
      //     nockOptions['filteringPath'].filter1,
      //     nockOptions['filteringPath'].filter2);
    }
    Interceptor scopeInterceptor =
        scope.get(nockOptions['path']); //..persist();

    var statusCode = testOptions is List ? testOptions[1] ?? 200 : 200;
    var filepath = "$folder/${nockOptions['file']}";
    var reply =
        testOptions is List && testOptions.length >= 3 ? testOptions[2] : null;
    if (!nock_nodeIsTruthy(reply) || testOptions == true) {
      var fileString = await getFileAsString(filepath);
      scopeInterceptor = scopeInterceptor..reply(statusCode, fileString);
    } else if (reply is String) {
      scopeInterceptor = scopeInterceptor..reply(200, reply);
    } else if (reply is Function) {
      var fileString = await getFileAsString(filepath);
      var body = testOptions[2](fileString);
      scopeInterceptor = scopeInterceptor..reply(200, body);
    }
    if (nockOptions['query'] != null) {
      scopeInterceptor.query((q) =>
          RegExp(nockOptions['query']).hasMatch(Uri(queryParameters: q).query));
    }

    scopes.add(scopeInterceptor);
  }

  if (nock_nodeIsTruthy(opts['watchJson'])) {
    await addScope(YT_HOST, opts['watchJson'], {
      'path': '/watch',
      'query': r'^v=.+&pbj=1$',
      'file': 'watch.json',
    });
  }

  if (nock_nodeIsTruthy(opts['watchHtml'])) {
    await addScope(YT_HOST, opts['watchHtml'], {
      'query': r'^v=.+&hl=en$',
      'path': '/watch',
      'file': 'watch.html',
    });
  }

  if (nock_nodeIsTruthy(opts['dashmpd'])) {
    // addScope(MANIFEST_HOST, opts.dashmpd, {
    //   filteringPath: [() => '/api/manifest/dash/'],
    //   get: '/api/manifest/dash/',
    //   file: 'dash-manifest.xml',
    // });
  }

  if (nock_nodeIsTruthy(opts['m3u8'])) {
    await addScope(M3U8_HOST, opts['m3u8'], {
      // 'filteringPath': ['/api/manifest/hls_variant/'],
      'get': '/api/manifest/hls_variant/',
      'file': 'hls-manifest.m3u8',
    });
  }

  if (nock_nodeIsTruthy(opts['player'])) {
    await addScope(YT_HOST, opts['player'], {
      // 'filteringPath': [RegExp(r'/player.+$'), '/player.js'],
      'path': '/s/player.js',
      'file': existingFiles
          .firstWhere((f) => RegExp(r'(html5)?player.+\.js$').hasMatch(f)),
    });
  }

  if (nock_nodeIsTruthy(opts['embed'])) {
    await addScope(YT_HOST, opts['embed'], {
      'query': 'hl=en',
      'path': '${EMBED_PATH + id}',
      'file': 'embed.html',
    });
  }

  if (nock_nodeIsTruthy(opts['get_video_info'])) {
    await addScope(YT_HOST, opts['get_video_info'], {
      'query': r'video_id=([a-zA-Z0-9_-]+)&(.+)$',
      'path': '${INFO_PATH}video_id=$id',
      'file': 'get_video_info',
    });
  }

  return NockFunctionReturn(scopes);
}

class NockFunctionReturn {
  final List<Interceptor> scopes;

  NockFunctionReturn(this.scopes);

  void done() => scopes.forEach((scope) => scope.cancel());

  urlReply(uri, statusCode, body, headers) {
    scopes.add(urlFunction(uri)..reply(statusCode, body, headers: headers));
  }

  urlReplyWithFile(uri, statusCode, file, headers) async {
    var fileString = await getFileAsString(file);

    scopes
        .add(urlFunction(uri)..reply(statusCode, fileString, headers: headers));
  }
}

filteringPath(uri, filter1, filter2) {
  var parsed = Uri.parse(uri);
  return nock(parsed.origin).get([
    (path) {
      var x = [filter1, filter2].any((dynamic x) {
        if (path is! String) {
          throw 'path is not string';
        }
        if (x is String && !path.contains(x)) {
          return false;
        } else if (x is RegExp && !x.hasMatch(path)) {
          return false;
        }
        throw 'not thought of';
      });

      return path
          .contains(parsed.path + parsed.query + parsed.hashCode.toString());
    }
  ]);
}

Interceptor urlFunction(uri) {
  var parsed = Uri.parse(uri);
  return nock(parsed.origin)
      .get(parsed.path + parsed.query + parsed.hashCode.toString());
}

Future<List<String>> fileNames(folder) async {
  var dir = await dirContents(Directory.fromUri(Uri.parse(folder)));

  return dir
      .where((e) => e is File)
      .map((e) => (e as File).path.split(Platform.pathSeparator).last)
      .toList();
}

Future<List<FileSystemEntity>> dirContents(Directory dir) {
  var files = <FileSystemEntity>[];
  var completer = Completer<List<FileSystemEntity>>();
  var lister = dir.list(recursive: false);
  lister.listen((file) => files.add(file),
      // should also register onError
      onDone: () => completer.complete(files));
  return completer.future;
}
