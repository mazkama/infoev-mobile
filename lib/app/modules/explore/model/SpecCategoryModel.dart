T cast<T>(dynamic value, String fieldName) {
  // Debug print opsional
  // print('DEBUG cast: $fieldName, value=$value, T=$T, value.runtimeType=${value?.runtimeType}');
  if (value == null) return null as T;

  // Handle int and int? from String or int (universal)
  if ((T == int || RegExp(r'^int(\?|)$').hasMatch(T.toString())) &&
      (value is String || value is int)) {
    if (value is int) return value as T;
    final intValue = int.tryParse(value.toString());
    if (intValue != null) return intValue as T;
    if (T.toString().contains('?')) return null as T;
  }

  // Handle String and String? from int or String
  if ((T == String || RegExp(r'^String(\?|)$').hasMatch(T.toString())) &&
      (value is int || value is String)) {
    return value.toString() as T;
  }

  if (value is T) return value;

  // print('Warning: field "$fieldName" expected $T but got ${value.runtimeType}');
  return value as T;
}

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
      id: cast<int>(json['id'], 'id'),
      name: cast<String>(json['name'], 'name'),
      priority: cast<int>(json['priority'], 'priority'),
      specs: (json['specs'] as List<dynamic>?)
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
  final List<String>? listItems;

  SpecItem({
    required this.id,
    required this.name,
    this.unit,
    this.type,
    this.value,
    this.valueDesc,
    this.valueBool,
    this.listItems,
  });

  factory SpecItem.fromJson(Map<String, dynamic> json) {
    String? value;
    String? valueDesc;
    bool? valueBool;
    List<String>? listItems;

    if (json['vehicles'] != null && (json['vehicles'] as List).isNotEmpty) {
      final vehicle = json['vehicles'][0];
      if (vehicle['pivot'] != null) {
        final pivot = vehicle['pivot'];
        value = pivot['value']?.toString();
        valueDesc = pivot['value_desc'];
        valueBool = pivot['value_bool'] == 1;
        if (pivot['list_items'] != null) {
          listItems = List<String>.from(pivot['list_items']);
        }
      }
    }

    return SpecItem(
      id: cast<int>(json['id'], 'id'),
      name: cast<String>(json['name'], 'name'),
      unit: cast<String?>(json['unit'], 'unit'),
      type: cast<String?>(json['type'], 'type'),
      value: value,
      valueDesc: valueDesc,
      valueBool: valueBool,
      listItems: listItems,
    );
  }

  String? getValue() {
    if (type == 'list' && listItems != null) {
      return listItems!.join(', ');
    }
    if (type == 'availability') {
      return valueBool == true ? 'Ya' : 'Tidak';
    }
    if (name == 'Pengisian Daya AC' && value != null && valueDesc != null) {
      return '$value jam ($valueDesc)';
    }
    if (valueDesc != null && valueDesc!.isNotEmpty) {
      return valueDesc;
    }
    if (value == null) return null;
    if (unit != null && unit!.isNotEmpty) {
      if (type == 'price') {
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