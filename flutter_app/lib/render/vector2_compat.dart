// vector2_compat.dart
import 'package:flame/extensions.dart' show Vector2; // Flame's (64-bit) Vector2
import 'package:vector_math/vector_math_64.dart' as vm;

/// Flame -> vm
extension FlameVector2ToVm on Vector2 {
  vm.Vector2 get asVm => vm.Vector2(x, y);
}

/// vm -> Flame (only if you ever need it)
extension VmVector2ToFlame on vm.Vector2 {
  Vector2 get asFlame => Vector2(x, y);
}
