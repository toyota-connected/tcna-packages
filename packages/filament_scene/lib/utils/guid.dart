import 'dart:math';

import 'package:safe_int_id/safe_int_id.dart';

typedef EntityGUID = int;

/*
 *  GUID generator
 */

final SafeIntId _generator = SafeIntId(
  firstYear: DateTime.now().year,
  random: Random.secure(),
  randomValues: 2048, // with this it's guaranteed to not crash for 138 years!
);


bool _firstTime = true;

EntityGUID generateGuid() {
  if (_firstTime) {
    print("Generator first year: ${_generator.firstYear}, last safe year: ${_generator.lastSafeYear}");
    _firstTime = false;
  }
  return _generator.getId();
}
