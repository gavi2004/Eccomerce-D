import 'package:flutter/material.dart';

class HomeCliente extends StatelessWidget {
  final String nombre;

  const HomeCliente({super.key, required this.nombre});

  String capitalizarNombre(String nombre) {
    if (nombre.isEmpty) return '';
    return nombre[0].toUpperCase() + nombre.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final nombreCapitalizado = capitalizarNombre(nombre);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - Cliente'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Text(
          'Bienvenido, $nombreCapitalizado',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
