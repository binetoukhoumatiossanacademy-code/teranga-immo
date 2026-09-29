final class ModelParsing {
  const ModelParsing._();

  static String requiredString(Map<String, dynamic> json, String key) {
    final value = nullableString(json, key);
    if (value == null) {
      throw FormatException('Champ obligatoire absent ou vide : $key');
    }
    return value;
  }

  static String? nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int requiredInt(Map<String, dynamic> json, String key) {
    final value = nullableInt(json, key);
    if (value == null)
      throw FormatException('Entier obligatoire absent : $key');
    return value;
  }

  static int? nullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    final parsed = int.tryParse(value.toString());
    if (parsed == null) throw FormatException('Entier invalide : $key');
    return parsed;
  }

  static bool requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('Booléen obligatoire invalide : $key');
  }

  static bool? nullableBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is bool) return value;
    throw FormatException('Booléen invalide : $key');
  }

  static DateTime? nullableDateTime(Map<String, dynamic> json, String key) {
    final value = nullableString(json, key);
    if (value == null) return null;
    return DateTime.tryParse(value) ??
        (throw FormatException('Date invalide pour $key : $value'));
  }

  static DateTime requiredDateTime(Map<String, dynamic> json, String key) =>
      nullableDateTime(json, key) ??
      (throw FormatException('Date obligatoire absente : $key'));

  static String requiredUuid(Map<String, dynamic> json, String key) =>
      validateUuid(requiredString(json, key), key);

  static String? nullableUuid(Map<String, dynamic> json, String key) {
    final value = nullableString(json, key);
    return value == null ? null : validateUuid(value, key);
  }

  static String validateUuid(String value, String field) {
    final normalized = value.trim().toLowerCase();
    final valid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ).hasMatch(normalized);
    if (!valid) throw FormatException('UUID invalide pour $field');
    return normalized;
  }
}
