import 'package:flutter/material.dart';
import '../../api_service.dart';

import '../home_admin.dart';
import 'list_users.dart';
import '../inventory/list_inventory.dart';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:lottie/lottie.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  CreateUserScreenState createState() => CreateUserScreenState();
}

class CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  String _nivelSeleccionado = 'cliente';
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  // Actualizar los valores para coincidir con los niveles del sistema
  int _getNivelValue() {
    switch (_nivelSeleccionado) {
      case 'admin':
        return 3;
      case 'empleado':
        return 2;
      case 'cliente':
        return 1;
      default:
        return 1; // Valor por defecto
    }
  }

  void _mostrarError(String mensaje, {bool isSuccess = false}) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: isSuccess ? DialogType.success : DialogType.error,
      animType: AnimType.scale,
      title: isSuccess ? '¡Éxito!' : 'Error',
      desc: mensaje,
      btnOkOnPress: () {},
      btnOkColor: isSuccess ? Colors.green : Colors.red,
    ).show();
  }

  // Agregar este import al inicio del archivo junto con los demás imports

  
  void _mostrarConfirmacion(String mensaje, VoidCallback onOk) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: '¡Éxito!',
      desc: mensaje,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Lottie.asset(
              'assets/lottie/create-user-succes.json',
              width: 200,
              height: 200,
              repeat: false,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      btnOkOnPress: onOk,
      btnOkColor: Colors.green,
    ).show();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (await _verificarDuplicados()) return;

    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.registerUser(
        _cedulaController.text,
        _correoController.text,
        _nombreController.text,
        _telefonoController.text,
        _passwordController.text,
        _getNivelValue(),
      );

      if (!mounted) return;

      if (response.startsWith('✅')) {
        _mostrarConfirmacion('Usuario creado exitosamente', () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserListScreen()),
          );
        });
      } else if (response.contains('token')) {
        _mostrarError('Sesión expirada. Por favor, inicie sesión nuevamente');
        Navigator.pushReplacementNamed(context, '/');
      } else {
        _mostrarError(response);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error al crear usuario: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _verificarDuplicados() async {
    setState(() => _isLoading = true);
    
    try {
      // Verificar cédula
      if (await ApiService.verificarCedula(_cedulaController.text)) {
        _mostrarError('La cédula ya está registrada');
        _cedulaController.clear();
        return true;
      }
      
      // Verificar correo
      if (await ApiService.verificarCorreo(_correoController.text)) {
        _mostrarError('El correo ya está registrado');
        _correoController.clear();
        return true;
      }
      
      // Verificar teléfono
      if (await ApiService.verificarTelefono(_telefonoController.text)) {
        _mostrarError('El teléfono ya está registrado');
        _telefonoController.clear();
        return true;
      }
      
      return false;
    } catch (e) {
      _mostrarError('Error al verificar duplicados');
      return true;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  icon: Icon(Icons.person),
                  helperText: 'Solo letras y espacios',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Este campo es requerido';
                  if (RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(value!)) {
                    return 'Solo se permiten letras y espacios';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cédula',
                  icon: Icon(Icons.badge),
                  helperText: 'Exactamente 8 caracteres',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Este campo es requerido';
                  if (value!.length != 8) return 'Debe tener exactamente 8 caracteres';
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Solo números permitidos';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  icon: Icon(Icons.email),
                  helperText: 'Debe ser outlook, gmail o proton',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Este campo es requerido';
                  if (!RegExp(r'^[^@]+@(outlook\.com|gmail\.com|proton\.me)$').hasMatch(value!)) {
                    return 'Solo se permite correos de outlook, gmail o proton';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  icon: Icon(Icons.phone),
                  helperText: 'Exactamente 11 números',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Este campo es requerido';
                  if (value!.length != 11) return 'Debe tener exactamente 11 números';
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Solo números permitidos';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  icon: Icon(Icons.lock),
                  helperText: 'Mínimo 8 caracteres, 1 mayúscula, 1 número, 1 carácter especial',
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Este campo es requerido';
                  if (value!.length < 8) return 'Mínimo 8 caracteres';
                  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Debe contener al menos una mayúscula';
                  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Debe contener al menos un número';
                  if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                    return 'Debe contener al menos un carácter especial (!@#\$&*~)';
                  }
                  if (RegExp(_cedulaController.text).hasMatch(value) ||
                      RegExp(_telefonoController.text).hasMatch(value)) {
                    return 'No debe contener información de documentos oficiales';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _nivelSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Nivel',
                  icon: Icon(Icons.admin_panel_settings),
                ),
                validator: (value) =>
                    value == null ? 'Debe seleccionar un nivel' : null,
                items: const [
                  DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                  DropdownMenuItem(value: 'empleado', child: Text('Empleado')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _nivelSeleccionado = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Crear Usuario'),
              ),
            ],
          ),
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
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeAdmin()),
                  );
                },
              ),
              _buildNavButton(
                icon: Icons.people,
                label: 'Usuarios',
                isSelected: true,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const UserListScreen()),
                  );
                },
              ),
              _buildNavButton(
                icon: Icons.shopping_cart,
                label: 'Productos',
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ListInventoryScreen()),
                  );
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