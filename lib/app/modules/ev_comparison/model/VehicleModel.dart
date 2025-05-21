import 'package:intl/intl.dart';

T cast<T>(dynamic value, String fieldName) {
  if (value is T) return value;

  // Special handling if we expect an integer but the value is a string
  if (T == int && value is String) {
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue as T;
  }

  // Special handling if we expect a string but the value is an integer
  if (T == String && value is int) {
    return value.toString() as T;
  }

  print('Warning: field "$fieldName" expected $T but got ${value.runtimeType}');
  return value as T;
}


class VehicleModel {
  final int id;
  final String name;
  final String slug;
  final String brand;
  final String thumbnailUrl;
  final List<HighlightSpec> highlightSpecs;
  final List<SpecCategory> specCategories;

  VehicleModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.brand,
    required this.thumbnailUrl,
    required this.highlightSpecs,
    required this.specCategories,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'];
    final thumbnail = vehicle['pictures'][0]['path'];

    // Gunakan cast untuk memvalidasi tipe data
    final id = cast<int>(vehicle['id'], 'id');
    final name = cast<String>(vehicle['name'], 'name');
    final brand = cast<String>(vehicle['brand']['name'], 'brand');

    return VehicleModel(
      id: id,
      name: name,
      slug: cast<String>(vehicle['slug'], 'slug'),
      brand: brand,
      thumbnailUrl: 'https://infoev.mazkama.web.id/storage/$thumbnail',
      highlightSpecs:
          (json['highlightSpecs'] as List)
              .map((e) => HighlightSpec.fromJson(e))
              .toList(),
      specCategories:
          (json['specCategories'] as List)
              .map((e) => SpecCategory.fromJson(e))
              .toList(),
    );
  }
}

class HighlightSpec {
  final String type;
  final dynamic value;
  final String? unit;

  HighlightSpec({required this.type, required this.value, this.unit});

  factory HighlightSpec.fromJson(Map<String, dynamic> json) {
    return HighlightSpec(
      type: cast<String>(
        json['type'],
        'type',
      ), // Menggunakan cast untuk tipe data
      value: json['value'],
      unit: cast<String?>(json['unit'], 'unit'), // Pastikan unit bisa null
    );
  }
}

class SpecCategory {
  final int id;
  final String name;
  final String priority;
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
      priority: cast<String>(json['priority'], 'priority'),  // Will convert int to String if needed
      specs:
          (json['specs'] as List)
              .map((e) => SpecItem.fromJson(e))
              .toList()
              .where((spec) => spec.vehicles.isNotEmpty)
              .toList(),
    );
  }
}

class SpecItem {
  final int id;
  final String name;
  final String? unit;
  final String? type;
  final List<SpecVehicleValue> vehicles;

  SpecItem({
    required this.id,
    required this.name,
    this.unit,
    this.type,
    required this.vehicles,
  });

  factory SpecItem.fromJson(Map<String, dynamic> json) {
    return SpecItem(
      id: cast<int>(json['id'], 'id'),
      name: cast<String>(json['name'], 'name'),
      unit: cast<String?>(json['unit'], 'unit'),
      type: cast<String?>(json['type'], 'type'),
      vehicles:
          (json['vehicles'] as List)
              .map((e) => SpecVehicleValue.fromJson(e))
              .toList(),
    );
  }

  /// Ambil nilai berdasarkan slug kendaraan
  String? getVehicleValueBySlug(String slug) {
    final match = vehicles.firstWhere(
      (v) => v.vehicleSlug == slug,
      orElse: () => SpecVehicleValue.empty(),
    );
    return match.getDisplayWithUnit(itemUnit: unit, itemType: type);
  }
}

class SpecVehicleValue {
  final int vehicleId;
  final String vehicleSlug;
  final String? value;
  final String? unit;
  final bool? valueBool;

  SpecVehicleValue({
    required this.vehicleId,
    required this.vehicleSlug,
    this.value,
    this.unit,
    this.valueBool,
  });

  factory SpecVehicleValue.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'];
    final rawValue = pivot['value'];
    final rawDesc = pivot['value_desc'];
    final rawBool = pivot['value_bool'];

    // Use cast for vehicle_id as int
    final vehicleId = cast<int>(pivot['vehicle_id'], 'vehicle_id');  // cast to int
    final vehicleSlug = cast<String>(json['slug'], 'slug');
    
    return SpecVehicleValue(
      vehicleId: vehicleId,
      vehicleSlug: vehicleSlug,
      value: _parseNumber(rawValue),
      unit: cast<String?>(json['unit'], 'unit'),
      valueBool: _parseBool(pivot['value_bool']),
    );
  }


  String? getDisplayWithUnit({String? itemUnit, String? itemType}) {
    if (valueBool != null) return valueBool! ? '✓' : '✗';
    if (value == null || value.toString().toLowerCase() == "null") return null;

    if (itemType == 'price') {
      final number = double.tryParse(value!.replaceAll(RegExp(r'[^0-9]'), ''));
      if (number != null) return _formatRupiah(number);
      return 'Rp $value';
    }

    final suffix = (itemUnit?.isNotEmpty ?? false) ? itemUnit! : (unit ?? '');
    return suffix.isNotEmpty ? '$value $suffix' : value;
  }

  static String _parseNumber(dynamic val) {
    try {
      final number = double.tryParse(val.toString());
      if (number != null) {
        return number.toStringAsFixed(
          number.truncateToDouble() == number ? 0 : 2,
        );
      }
      return val.toString();
    } catch (_) {
      return val.toString();
    }
  }

  static String _formatRupiah(double number) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return '${formatter.format(number)},-';
  }

  static bool? _parseBool(dynamic input) {
    if (input == null) return null;
    if (input is bool) return input;
    if (input is int) return input == 1;
    return null;
  }

  static SpecVehicleValue empty() => SpecVehicleValue(
    vehicleId: -1,
    vehicleSlug: '',
    value: null,
    unit: null,
    valueBool: null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecVehicleValue &&
          runtimeType == other.runtimeType &&
          vehicleId == other.vehicleId;

  @override
  int get hashCode => vehicleId.hashCode;
}