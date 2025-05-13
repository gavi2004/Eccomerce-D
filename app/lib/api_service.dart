import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.101.7:5000'; // IP real del backend
  static bool isConnected = false;

  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<String> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ping'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        isConnected = true;
        return '✅ Conectado desde IP: ${data['ip']}';
      }
      isConnected = false;
      return '❌ No se pudo conectar';
    } catch (e) {
      isConnected = false;
      return '❌ Error: $e';
    }
  }

  static Future<Map<String, dynamic>> loginUser(String correo, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'correo': correo, 'contrasena': contrasena}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['token'] != null) {
          await saveToken(data['token']); // Guardar JWT
        }

        return {'success': true, 'user': data['usuario']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Error de autenticación'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  static Future<bool> verificarCedula(String cedula) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/cedula/$cedula'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String> registerUser(
    String cedula,
    String correo,
    String nombre,
    String telefono,
    String contrasena,
    int nivel,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cedula': cedula,
          'correo': correo,
          'nombre': nombre,
          'telefono': telefono,
          'contrasena': contrasena,
          'nivel': nivel,
        }),
      );

      if (response.statusCode == 201) {
        return '✅ Usuario registrado correctamente';
      } else {
        final data = json.decode(response.body);
        final error = data['error'] ?? 'Error desconocido';
        return '❌ $error';
      }
    } catch (e) {
      return '❌ Error al conectar con el servidor: $e';
    }
  }
}

final storage = FlutterSecureStorage();

Future<Map<String, dynamic>> obtenerDatosProtegidos() async {
  String? token = await storage.read(key: 'jwt_token');
  if (token == null) {
    return {'success': false, 'error': 'No token found'};
  }

  final response = await http.get(
    Uri.parse('http://192.168.101.7:5000/ruta-protegida'),
    headers: {'x-auth-token': token}, // Incluir el JWT en el encabezado
  );

  return response.statusCode == 200
      ? {'success': true, 'data': response.body}
      : {'success': false, 'error': 'Error de acceso'};
}
