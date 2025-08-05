import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/styles/app_colors.dart';

enum ErrorType {
  network,
  server,
  validation,
  authentication,
  unknown
}

class AppException implements Exception {
  final String message;
  final ErrorType type;
  final int? statusCode;
  final dynamic originalError;

  AppException({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
  });
}

class ErrorHandlerService {
  static void handleError(
    dynamic error, {
    bool showToUser = true,
    String? customMessage,
    bool logError = true,
  }) {
    final appError = _mapToAppException(error);
    
    // Log untuk development
    if (kDebugMode && logError) {
      debugPrint('🚨 Error: ${appError.message}');
      debugPrint('📍 Type: ${appError.type}');
      if (appError.originalError != null) {
        debugPrint('🔍 Original: ${appError.originalError}');
      }
    }
    
    // Tampilkan ke user jika diperlukan
    if (showToUser) {
      _showUserFriendlyMessage(customMessage ?? _getUserFriendlyMessage(appError));
    }
    
    // Log ke service di production (Firebase Crashlytics, Sentry, dll)
    if (!kDebugMode) {
      _logToRemoteService(appError);
    }
  }
  
  static AppException _mapToAppException(dynamic error) {
    if (error is AppException) return error;
    
    // Network errors
    if (error.toString().contains('SocketException') || 
        error.toString().contains('NetworkException')) {
      return AppException(
        message: 'Koneksi internet bermasalah',
        type: ErrorType.network,
      );
    }
    
    // HTTP errors
    if (error.toString().contains('404')) {
      return AppException(
        message: 'Data tidak ditemukan',
        type: ErrorType.server,
        statusCode: 404,
      );
    }
    
    if (error.toString().contains('401') || error.toString().contains('403')) {
      return AppException(
        message: 'Sesi berakhir, silakan login kembali',
        type: ErrorType.authentication,
        statusCode: 401,
      );
    }
    
    if (error.toString().contains('500')) {
      return AppException(
        message: 'Terjadi kesalahan pada server',
        type: ErrorType.server,
        statusCode: 500,
      );
    }
    
    return AppException(
      message: 'Terjadi kesalahan tidak terduga',
      type: ErrorType.unknown,
      originalError: error,
    );
  }
  
  static String _getUserFriendlyMessage(AppException error) {
    switch (error.type) {
      case ErrorType.network:
        return 'Periksa koneksi internet Anda dan coba lagi.';
      case ErrorType.server:
        return 'Server sedang bermasalah, silakan coba lagi nanti.';
      case ErrorType.validation:
        return 'Data yang dimasukkan tidak valid.';
      case ErrorType.authentication:
        return 'Sesi Anda telah berakhir, silakan login kembali.';
      case ErrorType.unknown:
      default:
        // Jika ada pesan custom, tampilkan pesan tersebut
        return error.message.isNotEmpty
            ? error.message
            : 'Terjadi kesalahan, silakan coba lagi.';
    }
  }
  
  static void _showUserFriendlyMessage(String message) {
    Get.rawSnackbar(
      backgroundColor: AppColors.errorColor.withOpacity(0.9),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      snackPosition: SnackPosition.TOP, // Ubah ke TOP
      duration: const Duration(seconds: 3),
      messageText: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.textOnPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static void _logToRemoteService(AppException error) {
    // Implementasi logging ke service external
    // Firebase Crashlytics, Sentry, dll
  }
  
  static void showSuccess(String message) {
    Get.rawSnackbar(
      backgroundColor: AppColors.successColor.withOpacity(0.9),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      snackPosition: SnackPosition.TOP, // Ubah ke TOP
      duration: const Duration(seconds: 2),
      messageText: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.textOnPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}