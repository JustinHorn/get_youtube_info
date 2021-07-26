import 'package:flutter_test/flutter_test.dart';

import 'helper.dart';

expectOk(dynamic x) => expect(nodeIsTruthy(x), true);
expectNotOk(dynamic x) => expect(nodeIsTruthy(x), false);
