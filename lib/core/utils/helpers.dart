/// Capitalizes the first letter of the provided [value].
String capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1);
}

/// Safely retrieves the first element of a list, returning `null` when empty.
T? firstOrNull<T>(List<T> values) {
  if (values.isEmpty) {
    return null;
  }

  return values.first;
}

/// Returns `true` when two lists contain the same items in the same order.
bool listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }

  if (first.length != second.length) {
    return false;
  }

  for (var i = 0; i < first.length; i++) {
    if (first[i] != second[i]) {
      return false;
    }
  }

  return true;
}
