import 'package:flutter/material.dart';
import 'package:app/api_service.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  bool _isRegistered = false;
  String _responseMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _cedulaController.dispose();
    _correoController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(String title, String message, DialogType type) async {
    await AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.bottomSlide,
      title: title,
      desc: message,
      btnOkOnPress: () {},
      btnOkColor: type == DialogType.error ? Colors.red : Colors.orange,
    ).show();
  }

  Future<void> registrarUsuario() async {
    setState(() {
      _isLoading = true;
    });

    // Validar campos
    List<String> errores = [];

    if (_cedulaController.text.isEmpty) errores.add('• La cédula es obligatoria');
    if (_correoController.text.isEmpty) errores.add('• El correo es obligatorio');
    if (_nombreController.text.isEmpty) errores.add('• El nombre es obligatorio');
    if (_telefonoController.text.isEmpty) errores.add('• El teléfono es obligatorio');

    final contrasenaError = validarContrasena(_contrasenaController.text);
    if (contrasenaError != null) errores.add('• $contrasenaError');

    if (errores.isNotEmpty) {
      setState(() => _isLoading = false);
      await _showErrorDialog(
        'Formulario incompleto',
        'Por favor corrige los siguientes errores:\n\n${errores.join('\n')}',
        DialogType.warning,
      );
      return;
    }

    // Verificar cédula existente
    try {
      final cedulaExistente = await ApiService.verificarCedula(_cedulaController.text);
      if (cedulaExistente) {
        setState(() => _isLoading = false);
        await _showErrorDialog(
          'Error de registro',
          'La cédula ya está registrada',
          DialogType.error,
        );
        return;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await _showErrorDialog(
        'Error de conexión',
        'No se pudo verificar la cédula. Por favor intenta nuevamente.',
        DialogType.error,
      );
      return;
    }

    // Registrar usuario
    try {
      final response = await ApiService.registerUser(
        _cedulaController.text,
        _correoController.text,
        _nombreController.text,
        _telefonoController.text,
        _contrasenaController.text,
        1,
      );

      setState(() => _isLoading = false);

      if (response.startsWith('✅')) {
        setState(() {
          _isRegistered = true;
          _responseMessage = response;
        });
      } else {
        await _showErrorDialog(
          'Error en el registro',
          response.replaceFirst('❌ ', ''),
          DialogType.error,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await _showErrorDialog(
        'Error de conexión',
        'No se pudo completar el registro. Por favor intenta nuevamente.',
        DialogType.error,
      );
    }
  }

  String? validarContrasena(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    } else if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una mayúscula';
    } else if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return 'La contraseña debe contener un carácter especial (!@#\$&*~)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: Colors.blue,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isRegistered
            ? Center(
                key: const ValueKey('success'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 80),
                    const SizedBox(height: 20),
                    Text(
                      _responseMessage,
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isRegistered = false;
                          _cedulaController.clear();
                          _correoController.clear();
                          _nombreController.clear();
                          _telefonoController.clear();
                          _contrasenaController.clear();
                          _responseMessage = '';
                        });
                      },
                      child: const Text('Registrar otro usuario'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                key: const ValueKey('form'),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInput(_cedulaController, 'Cédula', TextInputType.number),
                    const SizedBox(height: 10),
                    _buildInput(_correoController, 'Correo', TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _buildInput(_nombreController, 'Nombre'),
                    const SizedBox(height: 10),
                    _buildInput(_telefonoController, 'Teléfono', TextInputType.phone),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _contrasenaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white,
                        helperText: 'Mínimo 8 caracteres, 1 mayúscula y 1 carácter especial',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: registrarUsuario,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Registrar'),
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label,
      [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
    );
  }
}