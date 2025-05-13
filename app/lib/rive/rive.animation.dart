// rive_animation.dart
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveAnimationWidget extends StatelessWidget {
  const RiveAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RiveAnimation.asset(
        'assets/animations/your_animation.riv',  // Asegúrate de que esta ruta sea correcta
        fit: BoxFit.contain,  // Ajusta la animación a tu necesidad
      ),
    );
  }
}
