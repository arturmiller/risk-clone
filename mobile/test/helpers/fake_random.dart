import 'dart:math';

/// Returns pre-specified die faces (1-6) in sequence.
/// nextInt(max) returns (face - 1) so that nextInt(6) + 1 == face.
/// Throws StateError if exhausted.
class FakeRandom implements Random {
  final List<int> _values;
  int _index = 0;

  FakeRandom(List<int> values) : _values = values;

  @override
  int nextInt(int max) {
    if (_index >= _values.length) {
      throw StateError('FakeRandom exhausted at index $_index');
    }
    return _values[_index++] - 1;
  }

  @override
  double nextDouble() => throw UnimplementedError();

  @override
  bool nextBool() => throw UnimplementedError();
}
