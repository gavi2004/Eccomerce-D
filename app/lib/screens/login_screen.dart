import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/api_service.dart';
import 'package:app/screens/home_admin.dart';
import 'package:app/screens/home_cliente.dart';
import 'package:app/screens/home_empleado.dart';


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
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _checkBiometrics();
    await _checkCredencialesGuardadas();
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

      setState(() {
        _isLoading = false;
        _mensaje = result['success'] 
            ? '✅ Bienvenido ${result['user']['nombre']}' 
            : '❌ ${result['error']}';
      });

    if (result['success'] == true) {
  await _guardarCredenciales();

  if (mounted) {
    int nivel = result['user']['nivel']; // Obtener nivel correctamente

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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destino),
    );
  }

}


    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensaje = '❌ Error de conexión';
      });
      debugPrint('Error en login: $e');
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
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
    );
  }
}