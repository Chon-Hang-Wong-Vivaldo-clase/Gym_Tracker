/// calcular y exponer la racha de entrenamiento del usuario.
import 'package:flutter/foundation.dart';

class StreakProvider extends ChangeNotifier {
  int _streakDays = 0;
  int get streakDays => _streakDays;

  void setStreakDays(int value) {
    _streakDays = value;
    notifyListeners();
  }
}
