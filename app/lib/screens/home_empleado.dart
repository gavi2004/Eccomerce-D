import 'package:flutter/material.dart';

class HomeEmpleado extends StatelessWidget {
  const HomeEmpleado({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - Empleado'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Bienvenido, Empleado',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
