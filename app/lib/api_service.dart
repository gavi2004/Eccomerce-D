import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.101.2:5000'; // IP real del backend
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
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/users/cedula/$cedula'),
        headers: {'x-auth-token': token},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verificarCorreo(String correo) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/users/correo/$correo'),
        headers: {'x-auth-token': token},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verificarTelefono(String telefono) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/users/telefono/$telefono'),
        headers: {'x-auth-token': token},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
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
      final token = await getToken();
      if (token == null) {
        return '❌ No autorizado';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token
        },
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

  // Obtener todos los productos
  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autorizado'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'productos': json.decode(response.body)['productos']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Error al obtener productos'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // Crear nuevo producto
  static Future<Map<String, dynamic>> createProduct({
    required String nombre,
    required String marca,
    required String categoria,
    required int existencias,
    required double precio,
    String? imagen,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'No hay token disponible'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: json.encode({
          'nombre': nombre,
          'marca': marca,
          'categoria': categoria,
          'existencias': existencias,
          'precio': precio,
          if (imagen != null) 'imagen': imagen,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Error al crear el producto: $e'};
    }
  }

  // Actualizar producto
  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': '❌ No autorizado'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token
        },
        body: json.encode(productData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'mensaje': '✅ Producto actualizado correctamente',
          'producto': json.decode(response.body)['producto']
        };
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'error': '❌ ${data['error'] ?? 'Error al actualizar producto'}'};
      }
    } catch (e) {
      return {'success': false, 'error': '❌ Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkProductNameExists(String nombre, {String? excludeId}) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'No hay token disponible'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/products/check-name'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: json.encode({
          'nombre': nombre,
          if (excludeId != null) 'excludeId': excludeId,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Error al verificar el nombre: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'error': 'No hay token disponible'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Error al eliminar el producto: $e'};
    }
  }

  static Future<Map<String, dynamic>> obtenerDatosProtegidos() async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found'};
    }

    final response = await http.get(
      Uri.parse('$baseUrl/ruta-protegida'),
      headers: {'x-auth-token': token},
    );

    return response.statusCode == 200
        ? {'success': true, 'data': response.body}
        : {'success': false, 'error': 'Error de acceso'};
  }

  static Future<Map<String, dynamic>> getCarrito(String usuarioId) async {
    final response = await http.get(Uri.parse('$baseUrl/carrito/$usuarioId'));
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> addToCarrito(String usuarioId, Map<String, dynamic> producto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/carrito/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'usuarioId': usuarioId, 'producto': producto}),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> removeFromCarrito(String usuarioId, String productoId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/carrito/remove'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'usuarioId': usuarioId, 'productoId': productoId}),
    );
    return json.decode(response.body);
  }
}
