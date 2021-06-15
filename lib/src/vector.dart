import 'dart:math';

class Vector {
  double x;
  double y;
  double z;
  double w;

  Vector({double x: 0.0, double y: 0.0, double z: 0.0, double w: 0.0})
      : this.x = x,
        this.y = y,
        this.z = z,
        this.w = w;

  /// Multiply each component in the vector by 'factor'.
  void mul(double factor) {
    x *= factor;
    y *= factor;
    z *= factor;
    w *= factor.abs();
  }

  /// Subtract a vector from this one.
  void sub(Vector vec) {
    x -= vec.x;
    y -= vec.y;
    z -= vec.z;
    w -= vec.w;
  }

  double magnitude() {
    return sqrt((x * x) + (y * y) + (z * z));
  }

  /// Return the dot product
  double dot(Vector vec) {
    return (x * vec.x) + (y * vec.y) + (z * vec.z);
  }

  ///Calculate the angle between this vector and another
  double angle(Vector vec) {
    return acos(this.dot(vec) / (this.magnitude() * vec.magnitude()));
  }
}
