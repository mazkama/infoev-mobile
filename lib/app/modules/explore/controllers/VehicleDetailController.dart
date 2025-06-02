import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/explore/model/SpecCategoryModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:infoev/core/local_db.dart';
import 'package:infoev/app/modules/explore/model/CommentModel.dart';

class VehicleDetailController extends GetxController {
  // Data state
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = "".obs;

  // Vehicle data
  var vehicleId = 0.obs;
  var vehicleName = "".obs;
  var vehicleSlug = "".obs;
  var vehicleLoved = false.obs;
  var specCategories = <SpecCategory>[].obs;
  var vehicleImages = <String>[].obs;
  var highlightSpecs = [].obs;
  var affiliateLinks = [].obs;
  var comments = <Comment>[].obs;

  var isLoggedIn = false.obs;
  int commentCount = 0;

  @override
  void onInit() {
    super.onInit();
    // Cek token saat inisialisasi dan update isLoggedIn
    isLoggedIn.value = LocalDB.getToken() != null;
    final slug = Get.parameters['slug'];
    if (slug != null) {
      fetchVehicleDetails(slug);
    }
  }

  Future<bool> postComment({
    required String type, // misal: 'vehicle'
    required int id, // id kendaraan atau lainnya
    required String comment, // isi komentar
    int? parent, // id comment induk jika balasan, boleh null
  }) async {
    final token = LocalDB.getToken();
    final name = LocalDB.getName();

    if (token == null || token.isEmpty) {
      errorMessage.value = 'Token tidak tersedia. Silakan login kembali.';
      return false;
    }

    final url = Uri.parse('${baseUrlDev}/comment/store');

    final body = jsonEncode({
      'type': type,
      'id': id,
      'name': name,
      'comment': comment,
      'parent': parent,
    });

    print('Posting comment: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        print('Komentar berhasil dibuat');
        return true;
      } else {
        print('Gagal membuat komentar: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saat mengirim komentar: $e');
      return false;
    }
  }

  Future<void> fetchVehicleDetails(String slug) async {
    isLoading.value = true;
    hasError.value = false;

    try {
      final token = LocalDB.getToken();

      final response = await http.get(
        Uri.parse('${baseUrlDev}/$slug'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse vehicle basic info
        final vehicleData = data['vehicle'];
        vehicleId.value = vehicleData['id'] ?? 0;
        vehicleName.value = vehicleData['name'] ?? '';
        vehicleSlug.value = vehicleData['slug'] ?? '';

        // Parse vehicle loved status
        vehicleLoved.value = data['isLoved'] ?? false;

        // Comment count
        commentCount = data['comments_count'] ?? 0;

        // Parse comments
        if (data['comments'] != null) {
          comments.value =
              (data['comments'] as List)
                  .map((json) => Comment.fromJson(json))
                  .toList();
        }

        // Parse images
        if (vehicleData['pictures'] != null) {
          vehicleImages.value =
              (vehicleData['pictures'] as List)
                  .map(
                    (pic) =>
                        'https://infoev.mazkama.web.id/storage/${pic['path']}',
                  )
                  .toList();
        }

        // Parse spec categories
        if (data['specCategories'] != null) {
          final List<SpecCategory> categories = [];
          for (var categoryJson in data['specCategories']) {
            categories.add(SpecCategory.fromJson(categoryJson));
          }

          // Sort by priority
          categories.sort((a, b) => a.priority.compareTo(b.priority));
          specCategories.value = categories;
        }

        // Parse highlight specs
        highlightSpecs.value = data['highlightSpecs'] ?? [];

        // Parse affiliate links
        affiliateLinks.value = data['affiliateLinks'] ?? [];
      } else {
        hasError.value = true;
        errorMessage.value = "Error loading vehicle details";
        debugPrint('Error response: ${response.body}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "Network error occurred";
      debugPrint('Error in fetchVehicleDetails: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    if (vehicleSlug.value.isNotEmpty) {
      await fetchVehicleDetails(vehicleSlug.value);
    }
  }

  String getHighlightValue(String key) {
    try {
      final spec = (highlightSpecs as List).firstWhereOrNull(
        (spec) => spec['type'] == key,
      );

      if (spec != null) {
        return spec['value']?.toString() ?? '0';
      }
      return '0';
    } catch (e) {
      debugPrint('Error getting highlight value for $key: $e');
      return '0';
    }
  }

  String? getHighlightUnit(String key) {
    try {
      final spec = (highlightSpecs as List).firstWhereOrNull(
        (spec) => spec['type'] == key,
      );
      return spec?['unit'];
    } catch (e) {
      return null;
    }
  }

  String? getHighlightDesc(String key) {
    try {
      final spec = (highlightSpecs as List).firstWhereOrNull(
        (spec) => spec['type'] == key,
      );
      return spec?['desc'];
    } catch (e) {
      return null;
    }
  }

  String formatSpecValue(String value) {
    if (value.isEmpty) return value;

    // Check if it's a price value (contains Rp or IDR)
    if (value.toLowerCase().contains('rp') ||
        value.toLowerCase().contains('idr')) {
      return value; // Return price as is
    }

    try {
      // Split into value and unit if unit exists
      final parts = value.split(' ');
      if (parts.length > 1) {
        // Try to parse the number from the first part
        final numStr = parts[0].replaceAll(RegExp(r'[^0-9.,]'), '');
        if (numStr.isEmpty) return value;

        final num parsedNum = double.parse(numStr.replaceAll(',', '.'));

        // Format the number
        String formattedNumber;
        if (parsedNum == parsedNum.roundToDouble()) {
          formattedNumber = parsedNum.round().toString();
        } else {
          formattedNumber = parsedNum.toString();
        }

        // Combine with the unit
        return '$formattedNumber ${parts.sublist(1).join(' ')}';
      } else {
        // No unit, just format the number
        final numStr = value.replaceAll(RegExp(r'[^0-9.,]'), '');
        if (numStr.isEmpty) return value;

        final num parsedNum = double.parse(numStr.replaceAll(',', '.'));

        if (parsedNum == parsedNum.roundToDouble()) {
          return parsedNum.round().toString();
        }
        return parsedNum.toString();
      }
    } catch (e) {
      return value;
    }
  }
}
