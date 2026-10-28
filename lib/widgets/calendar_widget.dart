import 'package:flutter/material.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;

    final firstDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      1,
    ).weekday;

    final emptyDays = firstDay - 1;

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(12),

      color: Colors.white,

      child: Column(
        children: [

          const Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceAround,

            children: [
              Text('Sen'),
              Text('Sel'),
              Text('Rab'),
              Text('Kam'),
              Text('Jum'),
              Text('Sab'),
              Text('Min'),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: GridView.builder(
              itemCount:
              emptyDays +
                  daysInMonth,

              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),

              itemBuilder:
                  (context, index) {
                if (index < emptyDays) {
                  return const SizedBox();
                }

                final day =
                    index -
                        emptyDays +
                        1;

                final date =
                DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  day,
                );

                final selected =
                    date.year ==
                        selectedDate.year &&
                        date.month ==
                            selectedDate.month &&
                        date.day ==
                            selectedDate.day;

                return GestureDetector(
                  onTap: () {
                    onDateSelected(
                      date,
                    );
                  },

                  child: Container(
                    margin:
                    const EdgeInsets.all(
                      3,
                    ),

                    decoration:
                    BoxDecoration(
                      color: selected
                          ? const Color(
                        0xFFFF7A00,
                      )
                          : Colors
                          .transparent,

                      shape: BoxShape.circle,
                    ),

                    alignment:
                    Alignment.center,

                    child: Text(
                      '$day',

                      style:
                      TextStyle(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,

                        color: selected
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}