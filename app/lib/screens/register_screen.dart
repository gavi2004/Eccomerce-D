import 'package:flutter/material.dart';
import '../api_service.dart';
import 'login_screen.dart';
import 'index.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:lottie/lottie.dart';

// Puedes poner esto arriba de tu clase o en un archivo utils
void navegarConAnimacion(BuildContext context, Widget destino) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destino,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: mensaje,
      btnOkOnPress: () {},
      btnOkColor: Colors.red,
    ).show();
  }

  void _mostrarConfirmacion(String mensaje) {
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
              'assets/lottie/registro-exitoso.json',
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
      btnOkOnPress: () {
        navegarConAnimacion(context, const LoginScreen());
      },
      btnOkColor: Colors.green,
    ).show();
  }

  Future<bool> _verificarDuplicados() async {
    setState(() => _isLoading = true);
    
    try {
      if (await ApiService.verificarCedula(_cedulaController.text)) {
        _mostrarError('La cédula ya está registrada');
        _cedulaController.clear();
        return true;
      }
      
      if (await ApiService.verificarCorreo(_correoController.text)) {
        _mostrarError('El correo ya está registrado');
        _correoController.clear();
        return true;
      }
      
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

  Future<void> registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (await _verificarDuplicados()) return;

    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.registerUser(
        _cedulaController.text,
        _correoController.text,
        _nombreController.text,
        _telefonoController.text,
        _contrasenaController.text,
        1, // Nivel por defecto para registro normal
      );

      if (!mounted) return;

      if (response.startsWith('✅')) {
        _mostrarConfirmacion('Usuario registrado exitosamente');
      } else {
        _mostrarError(response);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error al registrar usuario: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Registro de Usuario',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
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
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
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
                              helperText: 'Exactamente 8 números',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Este campo es requerido';
                              if (value!.length != 8) return 'Debe tener 8 números';
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'Solo se permiten números';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _correoController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                              icon: Icon(Icons.email),
                              helperText: 'Correo de outlook, gmail o proton',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Este campo es requerido';
                              if (!RegExp(r'^[^@]+@(outlook\.com|gmail\.com|proton\.me)$')
                                  .hasMatch(value!)) {
                                return 'Debe ser un correo de outlook, gmail o proton';
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
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Este campo es requerido';
                              if (value!.length != 11) return 'Debe tener 11 números';
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'Solo se permiten números';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contrasenaController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              icon: Icon(Icons.lock),
                              helperText: 'Mínimo 8 caracteres, 1 mayúscula y 1 carácter especial',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Este campo es requerido';
                              if (value!.length < 8) return 'Mínimo 8 caracteres';
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return 'Debe contener al menos una mayúscula';
                              }
                              if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                                return 'Debe contener un carácter especial (!@#\$&*~)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: registrarUsuario,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Registrar'),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavButton(
                icon: Icons.home,
                label: 'Inicio',
                onTap: () {
                  navegarConAnimacion(context, const IndexPage());
                },
              ),
              _buildNavButton(
                icon: Icons.login,
                label: 'Iniciar Sesión',
                onTap: () {
                  navegarConAnimacion(context, const LoginScreen());
                },
              ),
              _buildNavButton(
                icon: Icons.person_add,
                label: 'Registro',
                isSelected: true,
                onTap: () {},
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
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}