import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerVehicleNew extends StatelessWidget {
  const ShimmerVehicleNew({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170, // ✅ Fix: total tinggi card
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 280, // ✅ Fix: lebar card
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar shimmer
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 90, height: 12, color: Colors.white), // Nama kendaraan
                          const SizedBox(height: 4),
                          Container(width: 60, height: 8, color: Colors.white),  // Brand
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
