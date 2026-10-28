import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                color: const Color(0xFFFFE5D0),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                size: 40,
                color: const Color(0xFFFF7A00),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              description,
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.black54,
              ),
            ),

            if (buttonText != null) ...[

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: onPressed,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                ),

                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}