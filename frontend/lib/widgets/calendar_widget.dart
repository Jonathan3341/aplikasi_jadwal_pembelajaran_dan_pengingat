import 'package:flutter/material.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  // Hari dalam seminggu yang memiliki jadwal.
  final Set<int> scheduledWeekdays;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.scheduledWeekdays = const {},
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;

    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1).weekday;

    final emptyDays = firstDay - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          // NAMA HARI
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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

          // TANGGAL KALENDER
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: emptyDays + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemBuilder: (context, index) {
                if (index < emptyDays) {
                  return const SizedBox();
                }

                final day = index - emptyDays + 1;

                final date = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  day,
                );

                final selected =
                    date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;

                // Periksa apakah hari ini memiliki jadwal.
                final hasSchedule = scheduledWeekdays.contains(date.weekday);

                return GestureDetector(
                  onTap: () {
                    onDateSelected(date);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF7A00)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 3),

                        // Indikator jadwal.
                        if (hasSchedule)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFFF7A00),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 5),
                      ],
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
