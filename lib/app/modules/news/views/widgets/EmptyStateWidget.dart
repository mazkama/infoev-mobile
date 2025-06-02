import 'package:flutter/material.dart';
import 'package:infoev/app/styles/app_colors.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onRetry;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.buttonText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 80,
            color: AppColors.secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null && buttonText != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}
