class ExerciseKeyUtil {
  static String make(String name) {
    final folded = name.toLowerCase();

    final words = folded
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return words.join('-');
  }
}
