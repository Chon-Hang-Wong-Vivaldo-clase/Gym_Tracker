import 'package:flutter/material.dart';

class WeekSwiper extends StatefulWidget {
  const WeekSwiper({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<WeekSwiper> createState() => _WeekSwiperState();
}

class _WeekSwiperState extends State<WeekSwiper> {
  late DateTime _selected;
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _selected = _onlyDate(widget.initialDate ?? DateTime.now());
    _days = _buildWeekCenteredOn(_selected);
  }

  // Quita horas/min/seg para comparar bien
  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> _buildWeekCenteredOn(DateTime center) {
    return List.generate(7, (i) => _onlyDate(center.add(Duration(days: i - 3))));
  }

  String _weekdayLetter(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'L';
      case DateTime.tuesday:
        return 'M';
      case DateTime.wednesday:
        return 'X';
      case DateTime.thursday:
        return 'J';
      case DateTime.friday:
        return 'V';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'D';
      default:
        return '';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final day = _days[i];
          final selected = _isSameDay(day, _selected);
          final theme = Theme.of(context);
          final onSurface = theme.colorScheme.onSurface;
          final surface = theme.colorScheme.surface;
          final isDark = theme.brightness == Brightness.dark;
          final selectedBg = selected
              ? (isDark ? theme.colorScheme.surfaceContainerHighest : const Color(0xFF2B2E34))
              : Colors.transparent;
          final selectedFg = selected
              ? (isDark ? onSurface : Colors.white)
              : onSurface;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => _selected = day);
              widget.onDateSelected(day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              decoration: BoxDecoration(
                color: selectedBg,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLetter(day),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selectedFg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? selectedFg : onSurface.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
