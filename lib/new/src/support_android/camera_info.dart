import '../common/camera_interface.dart';

enum Facing { back, front }

class CameraInfo implements CameraDescriptionNew {
  final int id;
  final Facing facing;
  final int orientation;

  const CameraInfo({
    required this.id,
    required this.facing,
    required this.orientation,
  });

  factory CameraInfo.fromMap(Map<String, dynamic> map) {
    return CameraInfo(
      id: map['id'],
      orientation: map['orientation'],
      facing: Facing.values.firstWhere(
        (Facing facing) => facing.toString() == map['facing'],
      ),
    );
  }

  @override
  String get name => id.toString();

  @override
  LensDirection get direction {
    switch (facing) {
      case Facing.front:
        return LensDirection.front;
      case Facing.back:
        return LensDirection.back;
    }
  }
}
