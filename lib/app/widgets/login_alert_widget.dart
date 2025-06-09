import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/app/styles/app_text.dart';

class LoginAlertWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const LoginAlertWidget({
    super.key,
    this.title = '',
    this.subtitle = '',
    this.icon,
  });

  static void show({
    String? title,
    String? subtitle,
    IconData? icon,
  }) {
    Get.bottomSheet(
      LoginAlertWidget(
        title: title ?? '',
        subtitle: subtitle ?? '',
        icon: icon,
      ),
      isDismissible: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  @override
  State<LoginAlertWidget> createState() => _LoginAlertWidgetState();
}

class _LoginAlertWidgetState extends State<LoginAlertWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    // Responsive values
    final double containerPadding = isTablet ? 16.w : 24.w;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _closeWithAnimation,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.textColor.withOpacity(0.3),
              child: SlideTransition(
                position: _slideAnimation,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from bubbling up to background
                    onPanUpdate: (details) {
                      if (details.delta.dy > 0) {
                        _closeWithAnimation();
                      }
                    },
                    child: Container(
                    padding: EdgeInsets.all(containerPadding),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackgroundColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(isTablet ? 18.r : 24.r)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium.withOpacity(0.15),
                          blurRadius: isTablet ? 24.r : 30.r,
                          spreadRadius: 0,
                          offset: Offset(0, isTablet ? 8.h : 10.h),
                        ),
                        BoxShadow(
                          color: AppColors.shadowMedium.withOpacity(0.08),
                          blurRadius: isTablet ? 48.r : 60.r,
                          spreadRadius: 0,
                          offset: Offset(0, isTablet ? 16.h : 20.h),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: isTablet ? 40.w : 50.w,
                            height: isTablet ? 4.h : 5.h,
                            margin: EdgeInsets.only(bottom: isTablet ? 18.h : 24.h),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary,
                              borderRadius: BorderRadius.circular(isTablet ? 2.r : 3.r),
                            ),
                          ),
                        ),
                        // Icon with modern gradient background
                        if (widget.icon != null)
                          Container(
                            width: isTablet ? 64.w : 80.w,
                            height: isTablet ? 64.w : 80.w,
                            margin: EdgeInsets.only(bottom: isTablet ? 18.h : 24.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.secondaryColor.withOpacity(0.1),
                                  AppColors.primaryColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.secondaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.icon!,
                              color: AppColors.secondaryColor,
                              size: isTablet ? 28.sp : 36.sp,
                            ),
                          ),
                        // Title
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: isTablet 
                            ? AppText.TitleBottomSheet.copyWith(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textColor,
                                height: 1.2,
                                letterSpacing: -0.5,
                              )
                            : AppText.TitleBottomSheet.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textColor,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                        ),
                        SizedBox(height: isTablet ? 8.h : 12.h),
                        // Subtitle
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: isTablet
                            ? AppText.BodyBottomSheet.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              )
                            : AppText.BodyBottomSheet.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        SizedBox(height: isTablet ? 20.h : 32.h),
                        // Login Button with modern design
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(isTablet ? 12.r : 16.r),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.primaryColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                blurRadius: isTablet ? 12.r : 15.r,
                                offset: Offset(0, isTablet ? 4.h : 6.h),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                              Get.toNamed('/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: isTablet ? 14.h : 18.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isTablet ? 12.r : 16.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Login Sekarang',
                              style: isTablet
                                ? AppText.buttonPrimary.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.textOnPrimary,
                                    letterSpacing: 0.2,
                                  )
                                : AppText.buttonPrimary.copyWith(
                                    color: AppColors.textOnPrimary,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 12.h : 16.h),
                        // Cancel Button with modern design
                        GestureDetector(
                          onTap: _closeWithAnimation,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: isTablet ? 12.h : 16.h),
                            child: Text(
                              'Nanti Saja',
                              textAlign: TextAlign.center,
                              style: isTablet
                                ? AppText.buttonPrimary.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  )
                                : AppText.buttonPrimary.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 6.h : 8.h),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _closeWithAnimation() {
    _animationController.reverse().then((_) {
      Get.back();
    });
  }
}