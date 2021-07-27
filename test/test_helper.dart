import 'package:flutter_test/flutter_test.dart';

import 'helper.dart';

expectOk(dynamic x) => expect(helper_nodeIsTruthy(x), true);
expectNotOk(dynamic x) => expect(helper_nodeIsTruthy(x), false);
