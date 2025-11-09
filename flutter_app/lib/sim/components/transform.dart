import 'package:vector_math/vector_math_64.dart';

class TransformComponent {
  TransformComponent({required this.position, required this.velocity});

  Vector2 position;
  Vector2 velocity;
}
