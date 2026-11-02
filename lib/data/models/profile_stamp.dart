/// How someone's photo sits on their postcard (Profile v4): a postage stamp
/// in one of six shapes and a colour they choose. Stored on `users/{uid}` as
/// `stampShape` and `stampColor`; missing or unknown values read as the
/// default (Classic, White) so older profiles and newer shapes never break.
enum StampShape {
  classic,
  rounded,
  round,
  soft,
  ticket,
  polaroid;

  static StampShape parse(Object? value) => StampShape.values.firstWhere(
    (s) => s.name == value,
    orElse: () => StampShape.classic,
  );
}

/// The stamp's paper colour: one of the app's colours by name, or any colour
/// as `#RRGGBB` (the "Any" picker).
class StampColor {
  const StampColor._(this.value);

  /// The paper colours offered first, in order (Figma page 13, Round 5).
  static const names = [
    'white',
    'paper',
    'green',
    'yellow',
    'orange',
    'red',
    'blue',
    'forest',
    'black',
  ];

  static const white = StampColor._('white');

  static final _hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// What is stored: a name from [names] or `#RRGGBB`.
  final String value;

  bool get isCustom => value.startsWith('#');

  /// The custom colour as 0xAARRGGBB; null for a named colour.
  int? get argb =>
      isCustom ? 0xFF000000 | int.parse(value.substring(1), radix: 16) : null;

  static StampColor named(String name) =>
      names.contains(name) ? StampColor._(name) : white;

  static StampColor custom(int argb) => StampColor._(
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
  );

  static StampColor parse(Object? value) {
    if (value is! String) return white;
    if (names.contains(value)) return StampColor._(value);
    if (_hex.hasMatch(value)) return StampColor._(value.toUpperCase());
    return white;
  }

  @override
  bool operator ==(Object other) => other is StampColor && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class ProfileStampStyle {
  const ProfileStampStyle({
    this.shape = StampShape.classic,
    this.color = StampColor.white,
  });

  final StampShape shape;
  final StampColor color;

  ProfileStampStyle copyWith({StampShape? shape, StampColor? color}) =>
      ProfileStampStyle(shape: shape ?? this.shape, color: color ?? this.color);

  @override
  bool operator ==(Object other) =>
      other is ProfileStampStyle &&
      other.shape == shape &&
      other.color == color;

  @override
  int get hashCode => Object.hash(shape, color);
}
