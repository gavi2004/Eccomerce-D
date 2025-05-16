import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/api_service.dart';
import 'package:app/screens/home_admin.dart';
import 'package:app/screens/home_cliente.dart';
import 'package:app/screens/home_empleado.dart';
import 'package:lottie/lottie.dart';
import 'index.dart'; // En login_screen.dart
import 'register_screen.dart'; // En login_screen.dart si no está ya importado

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  String _mensaje = '';
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _credencialesGuardadas = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _checkCredencialesGuardadas();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      setState(() {
        _biometricAvailable = canCheck && isDeviceSupported;
      });
    } on PlatformException catch (e) {
      debugPrint('Error al verificar biométricos: $e');
    }
  }

  Future<void> _checkCredencialesGuardadas() async {
    final correo = await storage.read(key: 'correo');
    final contrasena = await storage.read(key: 'contrasena');
    
    setState(() {
      _credencialesGuardadas = correo != null && contrasena != null;
    });
    
    // Si hay credenciales y biométricos disponibles, sugerir huella
    if (_credencialesGuardadas && _biometricAvailable) {
      _mostrarDialogoHuella();
    }
  }

  Future<void> _mostrarDialogoHuella() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Iniciar con huella'),
          content: const Text('¿Deseas iniciar sesión con tu huella digital?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loginConHuella();
              },
              child: const Text('Sí'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _mensaje = '';
    });

    try {
      final result = await ApiService.loginUser(
        _correoController.text.trim(),
        _contrasenaController.text.trim(),
      );

      if (result['success'] == true) {
        await _guardarCredenciales();
        await storage.write(key: 'usuario_id', value: result['user']['_id']);

        if (mounted) {
          // Mostrar diálogo con animación Lottie
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/lottie/login.json',
                      width: 200,
                      height: 200,
                      repeat: false,
                      onLoaded: (composition) {
                        Future.delayed(composition.duration, () {
                          Navigator.pop(context);
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '¡Bienvenido ${result['user']['nombre']}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );

          int nivel = result['user']['nivel'];
          Widget destino;

          if (nivel == 1) {
            destino = HomeCliente(nombre: result['user']['nombre']);
          } else if (nivel == 2) {
            destino = const HomeEmpleado();
          } else if (nivel == 3) {
            destino = const HomeAdmin();
          } else {
            destino = const Scaffold(
              body: Center(child: Text("Nivel no reconocido")),
            );
          }

          navegarConAnimacion(context, destino);
        }
      } else {
        setState(() {
          _mensaje = '❌ ${result['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensaje = '❌ Error de conexión';
      });
      debugPrint('Error en login: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarCredenciales() async {
    try {
      await storage.write(key: 'correo', value: _correoController.text.trim());
      await storage.write(key: 'contrasena', value: _contrasenaController.text.trim());
      setState(() {
        _credencialesGuardadas = true;
      });
    } catch (e) {
      debugPrint('Error guardando credenciales: $e');
    }
  }

  Future<void> _eliminarCredenciales() async {
    try {
      await storage.delete(key: 'correo');
      await storage.delete(key: 'contrasena');
      setState(() {
        _credencialesGuardadas = false;
      });
    } catch (e) {
      debugPrint('Error eliminando credenciales: $e');
    }
  }

  Future<void> _loginConHuella() async {
  try {
    setState(() {
      _isLoading = true;
      _mensaje = '';
    });

    final authenticated = await auth.authenticate(
      localizedReason: 'Autentícate con tu huella para iniciar sesión',
      options: const AuthenticationOptions(
        biometricOnly: true,
        useErrorDialogs: true,
        stickyAuth: true,
      ),
    );

    if (authenticated) {
      final correo = await storage.read(key: 'correo');
      final contrasena = await storage.read(key: 'contrasena');
      
      if (correo != null && contrasena != null) {
        _correoController.text = correo;
        _contrasenaController.text = contrasena;
        await _login();
      } else {
        setState(() {
          _mensaje = '❌ No hay credenciales guardadas';
          _isLoading = false;
        });
        await _eliminarCredenciales();
      }
    } else {
      setState(() {
        _mensaje = '❌ Autenticación cancelada';
        _isLoading = false;
      });
    }
  } on PlatformException catch (e) {
    setState(() {
      _mensaje = '❌ Error en autenticación biométrica: ${e.message}';
      _isLoading = false;
    });
    debugPrint('Error en huella: $e');
    
    // Si el error es específico de FragmentActivity, sugerir reinicio
    if (e.code == 'no_fragment_activity') {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error de configuración'),
            content: const Text('La aplicación necesita reiniciarse para aplicar los cambios necesarios.'),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Reiniciar'),
              ),
            ],
          ),
        );
      }
    }
  } finally {
    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }
}

  bool _validarEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
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
                      'Iniciar Sesión',
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
                        mainAxisSize: MainAxisSize.min, // Agregamos esta línea
                        children: [
                          TextFormField(
                            controller: _correoController,
                            decoration: const InputDecoration(labelText: 'Correo'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese su correo';
                              }
                              if (!_validarEmail(value)) {
                                return 'Ingrese un correo válido';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contrasenaController,
                            decoration: const InputDecoration(labelText: 'Contraseña'),
                            obscureText: true,
                            validator: (value) => 
                              value == null || value.isEmpty ? 'Ingrese su contraseña' : null,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Iniciar Sesión'),
                            ),
                          ),
                          if (_biometricAvailable && _credencialesGuardadas) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _loginConHuella,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.fingerprint),
                                    SizedBox(width: 8),
                                    Text('Usar huella digital'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_credencialesGuardadas) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _isLoading ? null : _eliminarCredenciales,
                              child: const Text(
                                'Eliminar credenciales guardadas', 
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            _mensaje,
                            style: TextStyle(
                              color: _mensaje.startsWith('✅') ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
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
                isSelected: true,
                onTap: () {},
              ),
              _buildNavButton(
                icon: Icons.person_add,
                label: 'Registro',
                onTap: () {
                  navegarConAnimacion(context, const RegisterScreen());
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