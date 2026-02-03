import 'package:flutter/material.dart';
import 'package:gym_tracker_app/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
         // LOGO
        actions: [
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(0, 0, 15, 0),
            child: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
          ),
        ],
      ),
      body: 
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(25, 0, 0, 10),
              child: Text("¡Buenos días!", style: TextStyle(fontSize: 22)),
            ),
            WeekSwiper(
              onDateSelected: (date) {
                print(date);
              },
            ),
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(0, 40, 0, 35),
              child: Center(
                child: StreakWaterRing(streakDays: 140, goalDays: 30, size: 260),
              ),
            ),
            Center(
              child: Text(
                "Seguimiento mensual",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          Divider(height: 30, endIndent: 30, indent: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatCard(
                title: "Entrenado",
                value: 21,
                background: const Color(0xFF2B2E34),
                textColor: Colors.white,
              ),
              const SizedBox(width: 14),
              StatCard(
                title: "Descanso",
                value: 12,
                background: const Color(0xFFBDBDBD),
                textColor: Colors.white,
              ),
            ],
          ),
          Divider(height: 30, endIndent: 30, indent: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatCard(
                title: "Entrenado",
                value: 21,
                background: const Color(0xFF2B2E34),
                textColor: Colors.white,
              ),
              const SizedBox(width: 14),
              StatCard(
                title: "Descanso",
                value: 12,
                background: const Color(0xFFBDBDBD),
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
      )
    );
  }
}
