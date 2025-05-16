import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app/api_service.dart';
import 'create_user.dart';
import '../home_admin.dart';
import '../../utils/navigation.dart';
import '../inventory/list_inventory.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedFilter = 'todos';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesSearch = user['nombre'].toString().toLowerCase().contains(searchLower) ||
            user['correo'].toString().toLowerCase().contains(searchLower) ||
            user['cedula'].toString().toLowerCase().contains(searchLower);

        if (_selectedFilter == 'todos') return matchesSearch;
        return matchesSearch && user['nivel'].toString() == _selectedFilter;
      }).toList();
    });
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String? token = await _storage.read(key: 'jwt_token');
      
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No autenticado. Por favor inicie sesión.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/users'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _users = data['users'] ?? [];
          _filteredUsers = _users;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sesión expirada. Por favor inicie sesión nuevamente.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar usuarios: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final String? token = await _storage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado con éxito')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar usuario')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );

    if (result == true) {
      _fetchUsers();
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          user['nombre'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildInfoRow(Icons.credit_card, 'Cédula: ${user['cedula'] ?? 'N/A'}'),
            _buildInfoRow(Icons.email, 'Email: ${user['correo'] ?? 'N/A'}'),
            _buildInfoRow(Icons.phone, 'Teléfono: ${user['telefono'] ?? 'N/A'}'),
            _buildInfoRow(Icons.star, 'Nivel: ${user['nivel']?.toString() ?? '1'}'),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editUser(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar eliminación'),
                  content: const Text('¿Está seguro de que desea eliminar este usuario?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteUser(user['_id']);
                      },
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuarios...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterUsers();
              });
            },
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedFilter,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: 'todos', child: Text('Todos los niveles')),
              DropdownMenuItem(value: '1', child: Text('Nivel 1')),
              DropdownMenuItem(value: '2', child: Text('Nivel 2')),
              DropdownMenuItem(value: '3', child: Text('Nivel 3')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
                _filterUsers();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateUserScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchUsers,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? const Center(
                            child: Text('No hay usuarios que coincidan con la búsqueda'),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchUsers,
                            child: ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(_filteredUsers[index]);
                              },
                            ),
                          ),
          ),
        ],
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
                isSelected: false,
                onTap: () {
                 navegarConFade(context, const HomeAdmin());
                },
              ),
              _buildNavButton(
                icon: Icons.people,
                label: 'Usuarios',
                isSelected: true,
                onTap: () {}, // Ya estamos en list_users
              ),
              _buildNavButton(
                icon: Icons.shopping_cart,
                label: 'Productos',
                isSelected: false,
                onTap: () {
                 navegarConFade(context, const ListInventoryScreen());
                },
              ),
              _buildNavButton(
                icon: Icons.build,
                label: 'Servicios',
                isSelected: false,
                onTap: () {
                  // TODO: Implementar navegación a servicios
                },
              ),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserDialog({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late String _nivel;
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user['nombre']);
    _correoController = TextEditingController(text: widget.user['correo']);
    _telefonoController = TextEditingController(text: widget.user['telefono']);
    _nivel = widget.user['nivel'].toString();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final String? token = await _storage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/users/${widget.user['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: json.encode({
          'nombre': _nombreController.text,
          'correo': _correoController.text,
          'telefono': _telefonoController.text,
          'nivel': int.parse(_nivel),
        }),
      );

      print('Respuesta del servidor: ${response.body}'); // Agregar este log
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado con éxito')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar usuario')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Usuario'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Este campo es requerido' : null,
              ),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Este campo es requerido';
                  if (!value!.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Este campo es requerido' : null,
              ),
              DropdownButtonFormField<String>(
                value: _nivel,
                decoration: const InputDecoration(labelText: 'Nivel'),
                items: ['1', '2', '3']
                    .map((nivel) => DropdownMenuItem(
                          value: nivel,
                          child: Text('Nivel $nivel'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _nivel = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _updateUser,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}