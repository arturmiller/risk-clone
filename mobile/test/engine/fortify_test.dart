// ignore_for_file: unused_import
// TODO: Uncomment when mobile/lib/engine/fortify.dart is implemented
// import 'package:risk_mobile/engine/fortify.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateFortify', () {
    test(
      'validateFortify: connected path allows move',
      () {},
      skip: 'not implemented',
    );

    test(
      'validateFortify: disconnected path throws',
      () {},
      skip: 'not implemented',
    );

    test(
      'validateFortify: source not owned throws',
      () {},
      skip: 'not implemented',
    );

    test(
      'validateFortify: target not owned throws',
      () {},
      skip: 'not implemented',
    );

    test(
      'validateFortify: moving all armies (leaving 0) throws',
      () {},
      skip: 'not implemented',
    );
  });

  group('executeFortify', () {
    test(
      'executeFortify: armies deducted from source, added to target',
      () {},
      skip: 'not implemented',
    );

    test(
      'executeFortify: source army count = original - moved',
      () {},
      skip: 'not implemented',
    );

    test(
      'executeFortify: target army count = original + moved',
      () {},
      skip: 'not implemented',
    );
  });
}
