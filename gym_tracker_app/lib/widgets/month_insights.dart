import 'package:flutter/material.dart';

class MonthInsights extends StatefulWidget {
  const MonthInsights({
    super.key
    this.trainedDays
    this.restDays
  });

  final int trainedDays;
  final int restDays;

  @override
  State<MonthInsights> createState() => _MonthInsightsState();
}

class _MonthInsightsState extends State<MonthInsights> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

}