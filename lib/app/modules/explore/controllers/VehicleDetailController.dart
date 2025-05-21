import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/explore/model/SpecCategoryModel.dart';
import 'package:infoev/core/halper.dart'; 
 

class VehicleDetailController extends GetxController {
  // Data state
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = "".obs;

  // Vehicle data
  var vehicleName = "".obs;
  var vehicleSlug = "".obs;
  var specCategories = <SpecCategory>[].obs;
  var vehicleImages = <String>[].obs;
  var highlightSpecs = [].obs;
  var affiliateLinks = [].obs;

  @override
  void onInit() {
    super.onInit();
    final slug = Get.parameters['slug'];
    if (slug != null) {
      fetchVehicleDetails(slug);
    }
  }

  Future<void> fetchVehicleDetails(String slug) async {
    isLoading.value = true;
    hasError.value = false;
    
    try {
      final response = await http.get(Uri.parse('https://infoev.mazkama.web.id/api/$slug'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parse vehicle basic info
        final vehicleData = data['vehicle'];
        vehicleName.value = vehicleData['name'] ?? '';
        vehicleSlug.value = vehicleData['slug'] ?? '';
        
        // Parse images
        if (vehicleData['pictures'] != null) {
          vehicleImages.value = (vehicleData['pictures'] as List)
              .map((pic) => 'https://infoev.mazkama.web.id/storage/${pic['path']}')
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
        (spec) => spec['type'] == key
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
        (spec) => spec['type'] == key
      );
      return spec?['unit'];
    } catch (e) {
      return null;
    }
  }

  String? getHighlightDesc(String key) {
    try {
      final spec = (highlightSpecs as List).firstWhereOrNull(
        (spec) => spec['type'] == key
      );
      return spec?['desc'];
    } catch (e) {
      return null;
    }
  }

  String formatSpecValue(String value) {
    if (value.isEmpty) return value;
    
    // Check if it's a price value (contains Rp or IDR)
    if (value.toLowerCase().contains('rp') || value.toLowerCase().contains('idr')) {
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