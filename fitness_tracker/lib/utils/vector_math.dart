// Custom implementation of Matrix4 and Vector classes for web compatibility
class Matrix4 {
  final List<double> _values;

  Matrix4.zero() : _values = List.filled(16, 0.0);

  Matrix4.identity()
      : _values = [
          1.0, 0.0, 0.0, 0.0, 
          0.0, 1.0, 0.0, 0.0, 
          0.0, 0.0, 1.0, 0.0, 
          0.0, 0.0, 0.0, 1.0
        ];

  Matrix4.diagonal3Values(double x, double y, double z)
      : _values = [
          x, 0.0, 0.0, 0.0, 
          0.0, y, 0.0, 0.0, 
          0.0, 0.0, z, 0.0, 
          0.0, 0.0, 0.0, 1.0
        ];

  double operator [](int index) => _values[index];
  void operator []=(int index, double value) => _values[index] = value;

  // Simple transformation methods
  static Matrix4 translationValues(double x, double y, double z) {
    final m = Matrix4.identity();
    m[12] = x;
    m[13] = y;
    m[14] = z;
    return m;
  }

  // Scale transformation
  static Matrix4 diagonal3(double x, double y, double z) {
    return Matrix4.diagonal3Values(x, y, z);
  }

  // Clone this matrix
  Matrix4 clone() {
    final result = Matrix4.zero();
    for (var i = 0; i < 16; i++) {
      result[i] = this[i];
    }
    return result;
  }
}

// Simple Vector classes
class Vector3 {
  double x, y, z;
  
  Vector3(this.x, this.y, this.z);
  
  Vector3.zero() : x = 0.0, y = 0.0, z = 0.0;
}

class Vector4 {
  double x, y, z, w;
  
  Vector4(this.x, this.y, this.z, this.w);
  
  Vector4.zero() : x = 0.0, y = 0.0, z = 0.0, w = 0.0;
}

// Characters class to implement the missing functionality
class Characters {
  final String _string;
  
  Characters(this._string);
  
  Characters characterAt(int index) {
    if (index < 0 || index >= _string.length) {
      throw RangeError('Index out of range: $index');
    }
    return Characters(_string[index]);
  }
  
  @override
  String toString() => _string;
}

// Extension to add characters functionality to String
extension StringCharacters on String {
  Characters get characters => Characters(this);
}