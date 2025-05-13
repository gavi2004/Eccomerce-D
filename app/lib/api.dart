import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://192.168.101.7:5000'; // Usa tu IP local si estás en emulador físico

Future<List<String>> fetchTareas() async {
  final response = await http.get(Uri.parse('$baseUrl/tasks'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => item['texto'].toString()).toList(); // 'texto' es el campo en Mongo
  } else {
    throw Exception('Error al cargar tareas');
  }
}

Future<void> agregarTarea(String texto) async {
  final response = await http.post(
    Uri.parse('$baseUrl/tasks'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'texto': texto}),
  );

  if (response.statusCode != 200) {
    throw Exception('Error al agregar tarea');
  }
}
