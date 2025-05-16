import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'create_product.dart';
import '../home_admin.dart';
import '../users/list_users.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../utils/navigation.dart';

class ListInventoryScreen extends StatefulWidget {
  const ListInventoryScreen({super.key});

  @override
  State<ListInventoryScreen> createState() => _ListInventoryScreenState();
}

  

class _ListInventoryScreenState extends State<ListInventoryScreen> {
  List<dynamic> _productos = [];
  List<dynamic> _productosFiltrados = [];
  Set<String> _categorias = {};
  Set<String> _marcas = {};
  bool _isLoading = false;
  String _error = '';
  
  // Filtros
  String _busqueda = '';
  String? _categoriaSeleccionada;
  String? _marcaSeleccionada;
  RangeValues _rangoPrecio = const RangeValues(0, 10000);
  double _precioMaximo = 10000;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await ApiService.getProducts();
      if (response['success']) {
        setState(() {
          _productos = response['productos'];
          _productosFiltrados = _productos;
          
          _categorias = _productos.map<String>((p) => p['categoria'].toString()).toSet();
          _marcas = _productos.map<String>((p) => p['marca'].toString()).toSet();
          
          _precioMaximo = _productos.isEmpty ? 10000 : _productos.fold(0, (max, p) => 
            p['precio'] > max ? p['precio'].toDouble() : max);
          _rangoPrecio = RangeValues(0, _precioMaximo);
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Error al cargar productos';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _productosFiltrados = _productos.where((producto) {
        final coincideBusqueda = _busqueda.isEmpty ||
            producto['nombre'].toString().toLowerCase().contains(_busqueda.toLowerCase());

        final coincideCategoria = _categoriaSeleccionada == null ||
            producto['categoria'] == _categoriaSeleccionada;

        final coincideMarca = _marcaSeleccionada == null ||
            producto['marca'] == _marcaSeleccionada;

        final precio = producto['precio'].toDouble();
        final coincidePrecio = precio >= _rangoPrecio.start &&
            precio <= _rangoPrecio.end;

        return coincideBusqueda &&
            coincideCategoria &&
            coincideMarca &&
            coincidePrecio;
      }).toList();
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _busqueda = '';
      _categoriaSeleccionada = null;
      _marcaSeleccionada = null;
      _rangoPrecio = RangeValues(0, _precioMaximo);
      _aplicarFiltros();
    });
  }

  Future<void> _eliminarProducto(Map<String, dynamic> producto) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Está seguro que desea eliminar el producto "${producto['nombre']}"?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmacion == true) {
      setState(() => _isLoading = true);
      
      try {
        final response = await ApiService.deleteProduct(producto['_id']);
        if (!mounted) return;
        
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto eliminado exitosamente')),
          );
          await _cargarProductos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Error al eliminar el producto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _editarProducto(Map<String, dynamic> producto) async {
    final nombreController = TextEditingController(text: producto['nombre']);
    final marcaController = TextEditingController(text: producto['marca']);
    final categoriaController = TextEditingController(text: producto['categoria']);
    final existenciasController = TextEditingController(text: producto['existencias'].toString());
    final precioController = TextEditingController(text: producto['precio'].toString());
    File? imageFile;

    final editado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Producto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mostrar imagen actual o placeholder
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          setState(() {
                            imageFile = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: imageFile != null
                            ? Image.file(
                                imageFile!,
                                fit: BoxFit.cover,
                              )
                            : producto['imagen'] != null
                                ? Image.network(
                                    producto['imagen'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.error);
                                    },
                                  )
                                : const Icon(Icons.add_photo_alternate, size: 40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: marcaController,
                      decoration: const InputDecoration(labelText: 'Marca'),
                    ),
                    TextField(
                      controller: categoriaController,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                    TextField(
                      controller: existenciasController,
                      decoration: const InputDecoration(labelText: 'Existencias'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: precioController,
                      decoration: const InputDecoration(labelText: 'Precio'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Guardar'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          }
        );
      },
    );

    if (editado == true) {
      // Validar campos antes de actualizar
      if (nombreController.text.trim().isEmpty ||
          marcaController.text.trim().isEmpty ||
          categoriaController.text.trim().isEmpty ||
          existenciasController.text.trim().isEmpty ||
          precioController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los campos son requeridos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validar que existencias y precio sean números válidos
      int? existencias = int.tryParse(existenciasController.text.trim());
      double? precio = double.tryParse(precioController.text.trim());

      if (existencias == null || existencias < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las existencias deben ser un número entero positivo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (precio == null || precio <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El precio debe ser un número positivo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String? imageUrl = producto['imagen'];
        
        // Si se seleccionó una nueva imagen, súbela primero
        if (imageFile != null) {
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
            request.files.add(
              await http.MultipartFile.fromPath(
                'image',
                imageFile!.path, // Agregamos el operador '!' para asegurar que no es nulo
              ),
            );
            
            final streamedResponse = await request.send();
            final response = await http.Response.fromStream(streamedResponse);
            
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              imageUrl = data['url'];
            } else {
              throw Exception('Error al subir imagen: ${response.statusCode}');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al subir la imagen: $e'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        final response = await ApiService.updateProduct(
          producto['_id'],
          {
            'nombre': nombreController.text.trim(),
            'marca': marcaController.text.trim(),
            'categoria': categoriaController.text.trim(),
            'existencias': existencias,
            'precio': precio,
            'imagen': imageUrl,
          },
        );

        if (!mounted) return;

        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto actualizado exitosamente')),
          );
          await _cargarProductos();
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Error al actualizar el producto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/admin');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateProductScreen()),
              ).then((_) => _cargarProductos());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarProductos,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error, style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                      onPressed: _cargarProductos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Buscar productos',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _busqueda = value;
                              _aplicarFiltros();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              DropdownButton<String>(
                                hint: const Text('Categoría'),
                                value: _categoriaSeleccionada,
                                items: [null, ..._categorias].map((categoria) {
                                  return DropdownMenuItem(
                                    value: categoria,
                                    child: Text(categoria ?? 'Todas las categorías'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _categoriaSeleccionada = value;
                                    _aplicarFiltros();
                                  });
                                },
                              ),
                              const SizedBox(width: 16),
                              DropdownButton<String>(
                                hint: const Text('Marca'),
                                value: _marcaSeleccionada,
                                items: [null, ..._marcas].map((marca) {
                                  return DropdownMenuItem(
                                    value: marca,
                                    child: Text(marca ?? 'Todas las marcas'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _marcaSeleccionada = value;
                                    _aplicarFiltros();
                                  });
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _limpiarFiltros,
                                tooltip: 'Limpiar filtros',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rango de precio: \$${_rangoPrecio.start.toStringAsFixed(2)} - \$${_rangoPrecio.end.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            RangeSlider(
                              values: _rangoPrecio,
                              min: 0,
                              max: _precioMaximo,
                              divisions: 100,
                              labels: RangeLabels(
                                '\$${_rangoPrecio.start.toStringAsFixed(2)}',
                                '\$${_rangoPrecio.end.toStringAsFixed(2)}',
                              ),
                              onChanged: (RangeValues values) {
                                setState(() {
                                  _rangoPrecio = values;
                                  _aplicarFiltros();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_productosFiltrados.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No se encontraron productos',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final producto = _productosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: producto['imagen'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      producto['imagen'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                              title: Text(producto['nombre']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Marca: ${producto['marca']}'),
                                  Text('Categoría: ${producto['categoria']}'),
                                  Text('Existencias: ${producto['existencias']}'),
                                  Text('Precio: \$${producto['precio'].toStringAsFixed(2)}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editarProducto(producto),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _eliminarProducto(producto),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
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
                  navegarConFade(context, const HomeAdmin());
                },
              ),
              _buildNavButton(
                icon: Icons.people,
                label: 'Usuarios',
                isSelected: false,
                onTap: () {
                 navegarConFade(context, const UserListScreen());
                },
              ),
              _buildNavButton(
                icon: Icons.shopping_cart,
                label: 'Productos',
                isSelected: true,
                onTap: () {}, // Ya estamos en list_inventory
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