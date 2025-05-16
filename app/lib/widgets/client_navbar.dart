import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/home_cliente.dart';
import '../screens/store/store.dart';
import '../screens/store/carrito.dart';

class ClienteNavBar extends StatelessWidget {
  final int selectedIndex;
  final String nombre;

  const ClienteNavBar({super.key, required this.selectedIndex, required this.nombre});

  void _onItemTapped(BuildContext context, int index) async {
    if (index == selectedIndex) return;
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeCliente(nombre: nombre)),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const StorePage()),
        (route) => false,
      );
    } else if (index == 2) {
      final storage = const FlutterSecureStorage();
      final usuarioId = await storage.read(key: 'usuario_id');
      if (usuarioId != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CarritoPage(usuarioId: usuarioId)),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el usuario. Inicia sesión de nuevo.')),
        );
      }
    }
    // Puedes agregar lógica para Configuración si tienes esa pantalla
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationBar(
      onDestinationSelected: (index) => _onItemTapped(context, index),
      selectedIndex: selectedIndex,
      backgroundColor: colorScheme.primaryContainer,
      indicatorColor: colorScheme.secondaryContainer,
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.store),
          label: 'Tienda',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart),
          label: 'Carrito',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Configuración',
        ),
      ],
    );
  }
}