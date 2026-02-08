import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MonthlyWorkoutCalendar extends StatelessWidget {
  const MonthlyWorkoutCalendar({
    super.key,
    this.plannedDays = const {},
    this.streakDays = const {},
    this.onDayTapped,
    this.showLegend = true,
  });

  final Set<DateTime> plannedDays;
  final Set<DateTime> streakDays;
  final ValueChanged<DateTime>? onDayTapped;
  final bool showLegend;

  static const Color _todayColor = Colors.black;
  static const Color _plannedColor = Color(0xFFE0E0E0);
  static const Color _streakColor = Color(0xFFB0B0B0);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final focused = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(now.year - 2, 1, 1);
    final lastDay = DateTime(now.year + 2, 12, 31);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: focused,
          headerStyle: const HeaderStyle(
            titleCentered: false,
            formatButtonVisible: false,
            leftChevronVisible: true,
            rightChevronVisible: true,
            titleTextStyle: TextStyle(fontWeight: FontWeight.w600),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 12, color: Colors.black54),
            weekendStyle: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            isTodayHighlighted: false,
          ),
          selectedDayPredicate: (_) => false,
          onDaySelected: (selectedDay, _) {
            onDayTapped?.call(selectedDay);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, isOutside: false);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, isOutside: false);
            },
            outsideBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, isOutside: true);
            },
            disabledBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, isOutside: true);
            },
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 10),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _LegendItem(color: _todayColor, label: "Hoy"),
              _LegendItem(color: _streakColor, label: "Racha"),
              _LegendItem(
                color: Colors.white,
                label: "Descanso",
                outline: true,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDayCell(DateTime day, {required bool isOutside}) {
    final isToday = isSameDay(day, DateTime.now());
    final isStreak = _containsDay(streakDays, day);
    final isPlanned = _containsDay(plannedDays, day);

    Color? background;
    Color textColor = Colors.black87;

    if (isToday) {
      background = _todayColor;
      textColor = Colors.white;
    } else if (isStreak) {
      background = _streakColor;
    } else if (isPlanned) {
      background = _plannedColor;
    }

    if (isOutside) {
      textColor = Colors.black26;
      background = null;
    }

    return Center(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: textColor,
          ),
        ),
      ),
    );
  }

  bool _containsDay(Set<DateTime> days, DateTime day) {
    for (final entry in days) {
      if (isSameDay(entry, day)) return true;
    }
    return false;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.outline = false,
  });

  final Color color;
  final String label;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: outline ? Colors.white : color,
            shape: BoxShape.circle,
            border: outline ? Border.all(color: Colors.black45) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
