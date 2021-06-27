import 'package:get_youtube_info/get_youtube_info.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  //

  group('utils.between()', () {
    test('`left` postestioned at the start', () {
      final rs = between('<b>hello there friend</b>', '<b>', '</b>');
      expect(rs, 'hello there friend');
    });

    test('somewhere in the middle', () {
      final rs = between('something everything nothing', ' ', ' ');
      expect(rs, 'everything');
    });

    test('not found', () {
      final rs = between('oh oh _where_ is it', '<b>', '</b>');
      expect(rs, '');
    });

    test('`right` before `left`', () {
      final rs = between('>>> a <this> and that', '<', '>');
      expect(rs, 'this');
    });

    test('`right` not found', () {
      final rs = between('something [around[ somewhere', '[', ']');
      expect(rs, '');
    });
  });

  group('utils.cutAfterJSON()', () {
    test('Works with simple JSON', () {
      expect(cutAfterJSON('{"a": 1, "b": 1}'), '{"a": 1, "b": 1}');
    });
    test('Cut extra characters after JSON', () {
      expect(cutAfterJSON('{"a": 1, "b": 1}abcd'), '{"a": 1, "b": 1}');
    });
    test('Tolerant to string finalants', () {
      expect(cutAfterJSON('{"a": "}1", "b": 1}abcd'), '{"a": "}1", "b": 1}');
    });
    test('Tolerant to string with escaped quoting', () {
      expect(
          cutAfterJSON('{"a": "\\"}1", "b": 1}abcd'), '{"a": "\\"}1", "b": 1}');
    });
    test('works with nested', () {
      expect(
        cutAfterJSON('{"a": "\\"1", "b": 1, "c": {"test": 1}}abcd'),
        '{"a": "\\"1", "b": 1, "c": {"test": 1}}',
      );
    });
    test('Works with utf', () {
      expect(
        cutAfterJSON('{"a": "\\"фыва", "b": 1, "c": {"test": 1}}abcd'),
        '{"a": "\\"фыва", "b": 1, "c": {"test": 1}}',
      );
    });
    test('Works with \\\\ in string', () {
      expect(
        cutAfterJSON('{"a": "\\\\фыва", "b": 1, "c": {"test": 1}}abcd'),
        '{"a": "\\\\фыва", "b": 1, "c": {"test": 1}}',
      );
    });
    test('Works with \\\\ towards the end of a string', () {
      expect(
        cutAfterJSON('{"text": "\\\\"};'),
        '{"text": "\\\\"}',
      );
    });
    test('Works with [ as start', () {
      expect(
        cutAfterJSON('[{"a": 1}, {"b": 2}]abcd'),
        '[{"a": 1}, {"b": 2}]',
      );
    });
    test('Returns an error when not beginning with [ or {', () {
      expect(() {
        cutAfterJSON('abcd]}');
      },
          throwsA(contains(
              "Can't cut unsupported JSON \(need to begin with \[ or { \) but got:")));
    });
    test('Returns an error when missing closing bracket', () {
      expect(() {
        cutAfterJSON('{"a": 1,{ "b": 1}');
      },
          throwsA(contains(
              "Can't cut unsupported JSON \(no matching closing bracket found\)")));
    });
  });
}
