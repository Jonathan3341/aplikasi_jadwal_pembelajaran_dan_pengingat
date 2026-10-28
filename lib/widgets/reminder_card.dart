import 'package:flutter/material.dart';

import '../app_data.dart';

class ReminderCard extends StatelessWidget {
  final ReminderItem reminder;

  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,

        margin:
        const EdgeInsets.only(bottom: 10),

        padding:
        const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(10),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset:
              const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [

            Container(
              width: 40,
              height: 40,

              decoration: BoxDecoration(
                color:
                const Color(0xFFFFE5D0),
                borderRadius:
                BorderRadius.circular(10),
              ),

              child: const Icon(
                Icons.notifications_active,
                color:
                Color(0xFFFF7A00),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    reminder.title,

                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    reminder.description,

                    style:
                    const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _formatDate(
                      reminder.dueAt,
                    ),

                    style:
                    const TextStyle(
                      fontSize: 10,
                      color:
                      Color(0xFFFF7A00),
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                }

                if (value == 'delete') {
                  onDelete?.call();
                }
              },

              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}