class FixedStepClock {
  FixedStepClock({required this.fixedDt}) : _accumulator = 0;

  final double fixedDt;
  double _accumulator;
  double _lastTime = 0;

  void reset() {
    _accumulator = 0;
    _lastTime = 0;
  }

  Iterable<int> tick(double elapsedSeconds) sync* {
    if (_lastTime == 0) {
      _lastTime = elapsedSeconds;
      return;
    }
    var delta = elapsedSeconds - _lastTime;
    _lastTime = elapsedSeconds;
    if (delta > fixedDt * 5) {
      delta = fixedDt * 5;
    }
    _accumulator += delta;
    while (_accumulator >= fixedDt) {
      _accumulator -= fixedDt;
      yield 1;
    }
  }

  double get alpha => _accumulator / fixedDt;
}
