import 'package:flutter/material.dart';
import './users/list_users.dart';
import './inventory/list_inventory.dart';
import '../../utils/navigation.dart';
import 'package:lottie/lottie.dart';

class HomeAdmin extends StatelessWidget {
  const HomeAdmin({super.key});


  
  void _mostrarDialogoCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: const Text('Sí, cerrar sesión'),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                
                // Mostrar diálogo con animación Lottie
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset(
                            'assets/lottie/cerrar-sesion.json',
                            width: 300,
                            height: 300,
                            fit: BoxFit.contain,
                            repeat: false,
                            onLoaded: (composition) {
                              Future.delayed(composition.duration, () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/', // Ruta de la página de inicio de sesión
                                  (Route<dynamic> route) => false,
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Cerrando Sesión...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Panel de Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _mostrarDialogoCerrarSesion(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenido al Panel de Administrador!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          )],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavButton(
                icon: Icons.home,
                label: 'Inicio',
                isSelected: true,
                onTap: () {}, // Ya estamos en home_admin
              ),
              _buildNavButton(
                icon: Icons.people,
                label: 'Usuarios',
                isSelected: false,
                onTap: () {
                 navegarConFade(context, const UserListScreen());
                },
              ),
              _buildNavButton(
                icon: Icons.shopping_cart,
                label: 'Productos',
                isSelected: false,
                onTap: () {
                  navegarConFade(context, const ListInventoryScreen());
                },
              ),
              // Botón para futura implementación de servicios
              _buildNavButton(
                icon: Icons.build,
                label: 'Servicios',
                isSelected: false,
                onTap: () {
                  // TODO: Implementar navegación a servicios
                },
              ),
              // Botón para futura implementación de reportes
              _buildNavButton(
                icon: Icons.bar_chart,
                label: 'Reportes',
                isSelected: false,
                onTap: () {
                  // TODO: Implementar navegación a reportes
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Reducido de 16 a 8
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 20, // Reducido de 24 a 20
            ),
            const SizedBox(height: 2), // Reducido de 4 a 2
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontSize: 10, // Reducido de 12 a 10
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // Agregar manejo de desbordamiento
            ),
          ],
        ),
      ),
    );
  }
}