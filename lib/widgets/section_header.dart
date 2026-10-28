import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
          child: Text(
            title,

            style: const TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        TextButton(
          onPressed: onPressed,

          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}