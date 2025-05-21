import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/ev_comparison/model/VehicleModel.dart';
import 'package:infoev/core/halper.dart';

class EVComparisonController extends GetxController {
  var vehicleA = Rxn<VehicleModel>();
  var vehicleB = Rxn<VehicleModel>();

  var isLoadingA = false.obs;
  var isLoadingB = false.obs;
  var isSearching = false.obs;
  var isCompared = false.obs;

  // ────────────────────────────────────────────────────────────
  void selectVehicleA(String slug) => setVehicle(slug, true);
  void selectVehicleB(String slug) => setVehicle(slug, false);

  void compareNow() {
    if (vehicleA.value == null || vehicleB.value == null) {
      _showError('Pilih dua kendaraan terlebih dahulu');
      return;
    }

    if (vehicleA.value!.id == vehicleB.value!.id) {
      _showError('Tidak bisa membandingkan kendaraan yang sama');
      return;
    }

    isCompared.value = true;
  }

  void resetComparison() {
    vehicleA.value = null;
    vehicleB.value = null;
    isCompared.value = false;
  }

  // ────────────────────────────────────────────────────────────
  Future<void> setVehicle(String slug, bool isFirst) async {
    if (isFirst) {
      isLoadingA.value = true;
    } else {
      isLoadingB.value = true;
    }

    try {
      final data = await _fetchVehicleDetail(slug);
      final vehicle = VehicleModel.fromJson(data);

      if (isFirst) {
        vehicleA.value = vehicle;
      } else {
        vehicleB.value = vehicle;
      }
    } catch (e) {
      _showError('Tidak bisa memuat detail kendaraan: $e');
    } finally {
      if (isFirst) {
        isLoadingA.value = false;
      } else {
        isLoadingB.value = false;
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchVehicles(String query) async {
    isSearching.value = true;

    try {
      final encodedQuery = Uri.encodeComponent(
        query,
      );  
      final url = Uri.parse('${baseUrlDev}/cari?q=$encodedQuery');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        return List<Map<String, dynamic>>.from(body['vehicles']);
      } else {
        throw Exception('Gagal mencari kendaraan');
      }
    } catch (e) {
      _showError('Gagal mencari kendaraan: $e');
      return [];
    } finally {
      isSearching.value = false;
    }
  }

  Future<Map<String, dynamic>> _fetchVehicleDetail(String slug) async {
    final url = Uri.parse('${baseUrlDev}/$slug');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Gagal mengambil detail kendaraan');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Gagal',
      message,
      backgroundColor: Colors.red[400],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}
