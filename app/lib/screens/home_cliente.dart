import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/store/store.dart';
import '../screens/store/carrito.dart'; // Agrega esta línea
import '../../utils/navigation.dart';

class HomeCliente extends StatefulWidget {
  final String nombre;

  const HomeCliente({super.key, required this.nombre});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  int _selectedIndex = 0;

  String capitalizarNombre(String nombre) {
    if (nombre.isEmpty) return '';
    return nombre[0].toUpperCase() + nombre.substring(1).toLowerCase();
  }

  

  void _onItemTapped(int index) async {
    if (index == 1) {
      navegarConFade(context, const StorePage());
    } else if (index == 2) {
      final storage = const FlutterSecureStorage();
      final usuarioId = await storage.read(key: 'usuario_id');
      if (usuarioId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarritoPage(usuarioId: usuarioId),
          ),
        );
      } else {
        // Maneja el caso donde no hay usuario_id guardado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el usuario. Inicia sesión de nuevo.')),
        );
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreCapitalizado = capitalizarNombre(widget.nombre);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - Cliente'),
        backgroundColor: colorScheme.primary,
      ),
      body: _selectedIndex == 0
        ? Center(
            child: Text(
              'Bienvenido, $nombreCapitalizado',
              style: const TextStyle(fontSize: 24),
            ),
          )
        : _selectedIndex == 1
            ? const Center(child: Text('Tienda'))
            : _selectedIndex == 2
                ? const Center(child: Text('Carrito'))
                : const Center(child: Text('Configuración')),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
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
      ),
    );
  }
}
