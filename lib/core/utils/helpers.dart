/// Returns `true` if the provided string is null, empty, or contains only
/// whitespace characters.
bool isBlank(String? value) {
  return value == null || value.trim().isEmpty;
}

/// Safely parses a [String] into an [int], returning `null` on failure.
int? tryParseInt(String? value) {
  if (value == null) return null;
  return int.tryParse(value);
}

/// Converts a nullable value into a non-nullable one using [fallback].
T valueOrDefault<T>(T? value, T fallback) {
  return value ?? fallback;
}
