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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final focused = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(now.year - 2, 1, 1);
    final lastDay = DateTime(now.year + 2, 12, 31);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    // Colores que se ven en ambos temas (invertidos en oscuro)
    final todayColor = isDark ? onSurface : Colors.black;
    final todayTextColor = isDark ? surface : Colors.white;
    final streakColor = isDark ? const Color(0xFF757575) : const Color(0xFFB0B0B0);
    final plannedColor = isDark ? const Color(0xFF5C5C5C) : const Color(0xFFE0E0E0);
    final defaultTextColor = onSurface;
    final outsideTextColor = onSurface.withOpacity(0.4);
    final legendLabelColor = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: focused,
          headerStyle: HeaderStyle(
            titleCentered: false,
            formatButtonVisible: false,
            leftChevronVisible: true,
            rightChevronVisible: true,
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: onSurface),
            rightChevronIcon: Icon(Icons.chevron_right, color: onSurface),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 12, color: onSurface),
            weekendStyle: TextStyle(fontSize: 12, color: onSurface),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            isTodayHighlighted: false,
            defaultTextStyle: TextStyle(color: defaultTextColor),
            weekendTextStyle: TextStyle(color: defaultTextColor),
          ),
          selectedDayPredicate: (_) => false,
          onDaySelected: (selectedDay, _) {
            onDayTapped?.call(selectedDay);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildDayCell(
                context,
                day,
                isOutside: false,
                todayColor: todayColor,
                todayTextColor: todayTextColor,
                streakColor: streakColor,
                plannedColor: plannedColor,
                defaultTextColor: defaultTextColor,
                outsideTextColor: outsideTextColor,
              );
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildDayCell(
                context,
                day,
                isOutside: false,
                todayColor: todayColor,
                todayTextColor: todayTextColor,
                streakColor: streakColor,
                plannedColor: plannedColor,
                defaultTextColor: defaultTextColor,
                outsideTextColor: outsideTextColor,
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return _buildDayCell(
                context,
                day,
                isOutside: true,
                todayColor: todayColor,
                todayTextColor: todayTextColor,
                streakColor: streakColor,
                plannedColor: plannedColor,
                defaultTextColor: defaultTextColor,
                outsideTextColor: outsideTextColor,
              );
            },
            disabledBuilder: (context, day, focusedDay) {
              return _buildDayCell(
                context,
                day,
                isOutside: true,
                todayColor: todayColor,
                todayTextColor: todayTextColor,
                streakColor: streakColor,
                plannedColor: plannedColor,
                defaultTextColor: defaultTextColor,
                outsideTextColor: outsideTextColor,
              );
            },
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 10),
          Divider(height: 20, color: legendLabelColor.withOpacity(0.3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(
                color: todayColor,
                label: "Hoy",
                labelColor: legendLabelColor,
              ),
              _LegendItem(
                color: streakColor,
                label: "Racha",
                labelColor: legendLabelColor,
              ),
              _LegendItem(
                color: surface,
                label: "Descanso",
                labelColor: legendLabelColor,
                outline: true,
                outlineColor: onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    required bool isOutside,
    required Color todayColor,
    required Color todayTextColor,
    required Color streakColor,
    required Color plannedColor,
    required Color defaultTextColor,
    required Color outsideTextColor,
  }) {
    final isToday = isSameDay(day, DateTime.now());
    final isStreak = _containsDay(streakDays, day);
    final isPlanned = _containsDay(plannedDays, day);

    Color? background;
    Color textColor = defaultTextColor;

    if (isToday) {
      background = todayColor;
      textColor = todayTextColor;
    } else if (isStreak) {
      background = streakColor;
      textColor = defaultTextColor;
    } else if (isPlanned) {
      background = plannedColor;
      textColor = defaultTextColor;
    }

    if (isOutside) {
      textColor = outsideTextColor;
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
    required this.labelColor,
    this.outline = false,
    this.outlineColor,
  });

  final Color color;
  final String label;
  final Color labelColor;
  final bool outline;
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: outline ? color : color,
            shape: BoxShape.circle,
            border: outline
                ? Border.all(color: outlineColor ?? Colors.black45)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: labelColor),
        ),
      ],
    );
  }
}
