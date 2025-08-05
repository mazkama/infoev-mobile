import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/styles/app_colors.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/logo_infoev.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 32),
            Obx(() => controller.isLoading.value
                ? const BubbleLoading()
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class BubbleLoading extends StatefulWidget {
  const BubbleLoading({super.key});

  @override
  State<BubbleLoading> createState() => _BubbleLoadingState();
}

class _BubbleLoadingState extends State<BubbleLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double t = _controller.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              double offset = (t + i * 0.2) % 1.0;
              double dy = -8 * (1 - (offset * 2 - 1).abs());
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
