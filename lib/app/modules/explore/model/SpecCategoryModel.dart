class SpecCategory {
  final int id;
  final String name;
  final int priority;
  final List<SpecItem> specs;

  SpecCategory({
    required this.id,
    required this.name,
    required this.priority,
    required this.specs,
  });

  factory SpecCategory.fromJson(Map<String, dynamic> json) {
    return SpecCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      priority: json['priority'] as int? ?? 0,
      specs:
          (json['specs'] as List<dynamic>?)
              ?.map((spec) => SpecItem.fromJson(spec))
              .toList() ??
          [],
    );
  }
}

class SpecItem {
  final int id;
  final String name;
  final String? unit;
  final String? type;
  final String? value;
  final String? valueDesc;
  final bool? valueBool;

  SpecItem({
    required this.id,
    required this.name,
    this.unit,
    this.type,
    this.value,
    this.valueDesc,
    this.valueBool,
  });

  factory SpecItem.fromJson(Map<String, dynamic> json) {
    // Dapatkan nilai dari vehicle jika ada
    String? value;
    String? valueDesc;
    bool? valueBool;

    if (json['vehicles'] != null && (json['vehicles'] as List).isNotEmpty) {
      final vehicle = json['vehicles'][0];
      if (vehicle['pivot'] != null) {
        final pivot = vehicle['pivot'];
        value = pivot['value']?.toString();
        valueDesc = pivot['value_desc'];
        valueBool = pivot['value_bool'] == 1;
      }
    }

    return SpecItem(
      id: json['id'] as int,
      name: json['name'] as String,
      unit: json['unit'] as String?,
      type: json['type'] as String?,
      value: value,
      valueDesc: valueDesc,
      valueBool: valueBool,
    );
  }

  String? getValue() {
    if (type == 'availability') {
      return valueBool == true ? 'Ya' : 'Tidak';
    }

    // Khusus untuk Pengisian Daya AC, tampilkan value dan valueDesc
    if (name == 'Pengisian Daya AC' && value != null && valueDesc != null) {
      return '$value jam ($valueDesc)';
    }

    if (valueDesc != null && valueDesc!.isNotEmpty) {
      return valueDesc;
    }

    if (value == null) return null;
    if (unit != null && unit!.isNotEmpty) {
      if (type == 'price') {
        // Format nilai harga
        try {
          final price = double.parse(value!);
          final formatted = price
              .toStringAsFixed(0)
              .replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (match) => '${match[1]}.',
              );
          return '$unit $formatted';
        } catch (e) {
          return '$unit $value';
        }
      }
      return '$value $unit';
    }
    return value;
  }
}
