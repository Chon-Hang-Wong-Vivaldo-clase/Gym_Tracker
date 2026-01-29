import 'package:flutter/material.dart';
import 'package:gym_tracker_app/widgets/week_swiper.dart';
import 'package:gym_tracker_app/widgets/streak_water_ring.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
        AppBar(
          actions: [
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(0, 0, 15, 0),
              child:IconButton(onPressed: (){}, icon: Icon(Icons.menu)),
            )
          ],
        ),
      body: 
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(25, 0, 0, 10),
              child: 
                Text("¡Buenos días!", style: TextStyle(fontSize: 22),)
              ),
            WeekSwiper(
              onDateSelected: (date) {
                print(date);
              },
            ),
            Padding(padding: EdgeInsetsGeometry.fromLTRB(0, 40, 0, 35),
            child: 
              Center(
                child: StreakWaterRing(
                  streakDays: 140,
                  goalDays: 30,
                  size: 260,
                ),
              ),
            ),
            Center(
              child: 
                Text("Seguimiento mensual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
            ),
            Divider(
              height: 30,
              endIndent: 30,
              indent: 30,
            ),

          ],
        )
    );
  }
}
