import 'package:flutter/material.dart';
import '../screens/home_admin.dart';
import '../screens/users/list_users.dart';
import '../screens/inventory/list_inventory.dart';

class AdminNavBar extends StatelessWidget {
  final String currentRoute;

  const AdminNavBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              context,
              icon: Icons.home,
              label: 'Inicio',
              route: '/admin',
              widget: const HomeAdmin(),
            ),
            _buildNavButton(
              context,
              icon: Icons.people,
              label: 'Usuarios',
              route: '/users',
              widget: const UserListScreen(),
            ),
            _buildNavButton(
              context,
              icon: Icons.shopping_cart,
              label: 'Productos',
              route: '/inventory',
              widget: const ListInventoryScreen(),
            ),
            _buildNavButton(
              context,
              icon: Icons.build,
              label: 'Servicios',
              route: '/services',
              widget: null,
            ),
            _buildNavButton(
              context,
              icon: Icons.bar_chart,
              label: 'Reportes',
              route: '/reports',
              widget: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Widget? widget,
  }) {
    final bool isSelected = currentRoute == route;

    return InkWell(
      onTap: widget == null ? null : () {
        if (currentRoute != route) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => widget),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}