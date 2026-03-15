// ignore_for_file: unused_import
// TODO: Uncomment when mobile/lib/engine/combat.dart is implemented
// import 'package:risk_mobile/engine/combat.dart';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_random.dart';

void main() {
  group('resolveCombat', () {
    test(
      'resolveCombat 3v2: attacker rolls [6,5,4] defender [3,2] → attacker_losses=0, defender_losses=2',
      () {},
      skip: 'not implemented',
    );

    test(
      'resolveCombat tie goes to defender: [4] vs [4] → attacker_losses=1, defender_losses=0',
      () {},
      skip: 'not implemented',
    );

    test(
      'resolveCombat 1v1: [6] vs [5] → attacker_losses=0, defender_losses=1',
      () {},
      skip: 'not implemented',
    );

    test(
      'resolveCombat 1v2: attacker [4] defender [5,3] → attacker_losses=1, defender_losses=0',
      () {},
      skip: 'not implemented',
    );
  });

  group('executeAttack', () {
    test(
      'executeAttack reduces territory armies correctly',
      () {},
      skip: 'not implemented',
    );

    test(
      'executeAttack conquers territory and sets owner',
      () {},
      skip: 'not implemented',
    );

    test(
      'executeAttack validates: source not owned throws',
      () {},
      skip: 'not implemented',
    );

    test(
      'executeAttack validates: attacking own territory throws',
      () {},
      skip: 'not implemented',
    );

    test(
      'executeAttack validates: non-adjacent territories throw',
      () {},
      skip: 'not implemented',
    );
  });

  group('executeBlitz', () {
    test(
      'executeBlitz loops until conquest',
      () {},
      skip: 'not implemented',
    );

    test(
      'executeBlitz stops when attacker reduced to 1 army',
      () {},
      skip: 'not implemented',
    );

    test(
      'executeBlitz conquest leaves minimum legal army (attacker >= 1)',
      () {},
      skip: 'not implemented',
    );
  });

  group('statistical', () {
    test(
      'statistical: 3v2 attacker-wins-both within 0.5% of 37.17% over 10000 trials',
      () {},
      skip: 'not implemented',
    );

    test(
      'statistical: 3v2 defender-wins-both within 0.5% of 29.26% over 10000 trials',
      () {},
      skip: 'not implemented',
    );
  });
}
