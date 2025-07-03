// lib/widgets/card_skeleton_loader.dart
import 'package:flutter/material.dart';

class CardSkeletonLoader extends StatelessWidget {
  const CardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final cardHeight = MediaQuery.of(context).size.height * 0.6;
    final cardWidth = MediaQuery.of(context).size.width * 0.8;

    return Center(
      child: Container(
        height: cardHeight,
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 200, height: 28, color: Colors.grey.shade400, margin: const EdgeInsets.only(bottom: 12)),
                    Container(width: double.infinity, height: 16, color: Colors.grey.shade300, margin: const EdgeInsets.only(bottom: 8)),
                    Container(width: 150, height: 16, color: Colors.grey.shade300),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}