import 'package:flutter/material.dart';

import '../../api_service.dart';

import 'dart:convert';
// Remover esta línea ya que no se usa:
// import 'package:dio/dio.dart';

import '../home_admin.dart';
import '../users/list_users.dart';
import 'list_inventory.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}



class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _marcaController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _existenciasController = TextEditingController();
  final _precioController = TextEditingController();

  bool _isLoading = false;
  String _mensaje = '';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarImagen() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _crearProducto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile != null && _imageFile!.lengthSync() > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La imagen no debe superar los 5MB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _mensaje = '';
    });

    try {
      // Verificar si el nombre ya existe
      final nombreResponse = await ApiService.checkProductNameExists(_nombreController.text);
      if (nombreResponse['exists'] == true) {
        setState(() {
          _mensaje = '❌ Ya existe un producto con este nombre';
          _isLoading = false;
        });
        return;
      }

      String? imageUrl;
      if (_imageFile != null) {
        try {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('${ApiService.baseUrl}/upload'),
          );
          
          final token = await ApiService.getToken();
          if (token == null) {
            throw Exception('No se encontró el token de autenticación');
          }
          
          request.headers['x-auth-token'] = token;
          // Remover esta línea ya que MultipartRequest maneja automáticamente el Content-Type
          // request.headers['Content-Type'] = 'multipart/form-data';
          
          final mimeType = _imageFile!.path.toLowerCase().endsWith('.png') 
              ? 'image/png'
              : _imageFile!.path.toLowerCase().endsWith('.jpg') || _imageFile!.path.toLowerCase().endsWith('.jpeg')
                  ? 'image/jpeg'
                  : _imageFile!.path.toLowerCase().endsWith('.gif')
                      ? 'image/gif'
                      : 'application/octet-stream';
          
          print('MIME Type detectado: $mimeType'); // Agregar log para depuración
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              _imageFile!.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
          
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['url'] == null) {
              throw Exception('URL de imagen no recibida');
            }
            imageUrl = data['url'];
          } else {
            throw Exception('Error al subir imagen: ${response.statusCode}');
          }
        } catch (e) {
          setState(() {
            _mensaje = '❌ Error al subir la imagen: $e';
            _isLoading = false;
          });
          return;
        }
      }

      final response = await ApiService.createProduct(
        nombre: _nombreController.text,
        marca: _marcaController.text,
        categoria: _categoriaController.text,
        existencias: int.parse(_existenciasController.text),
        precio: double.parse(_precioController.text),
        imagen: imageUrl,
      );

      if (!mounted) return;

      if (response['success']) {
        setState(() {
          _mensaje = '✅ Producto creado exitosamente';
          // Limpiar el formulario
          _nombreController.clear();
          _marcaController.clear();
          _categoriaController.clear();
          _existenciasController.clear();
          _precioController.clear();
          _imageFile = null;
        });
      } else {
        setState(() {
          _mensaje = '❌ ${response['error'] ?? 'Error al crear el producto'}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensaje = '❌ Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate, size: 50),
                            Text('Agregar imagen'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La marca es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La categoría es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _existenciasController,
                decoration: const InputDecoration(
                  labelText: 'Existencias',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Las existencias son obligatorias';
                  }
                  final existencias = int.tryParse(value);
                  if (existencias == null) {
                    return 'Ingrese un número válido';
                  }
                  if (existencias < 0) {
                    return 'Las existencias no pueden ser negativas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final precio = double.tryParse(value);
                  if (precio == null) {
                    return 'Ingrese un precio válido';
                  }
                  if (precio < 0) {
                    return 'El precio no puede ser negativo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_mensaje.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _mensaje,
                    style: TextStyle(
                      color: _mensaje.startsWith('❌') ? Colors.red : Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _crearProducto,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Crear Producto',
                        style: TextStyle(fontSize: 18),
                      ),
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
                isSelected: false,
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
                isSelected: true,
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

  @override
  void dispose() {
    _nombreController.dispose();
    _marcaController.dispose();
    _categoriaController.dispose();
    _existenciasController.dispose();
    _precioController.dispose();
    super.dispose();
  }
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

