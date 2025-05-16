import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../widgets/client_navbar.dart';

class CarritoPage extends StatefulWidget {
  final String usuarioId;
  const CarritoPage({super.key, required this.usuarioId});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _productos = [];

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await ApiService.getCarrito(widget.usuarioId);
      if (response['success'] == true && response['carrito'] != null) {
        setState(() {
          _productos = response['carrito']['productos'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'No se encontró el carrito o está vacío.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  double get _total {
    double total = 0;
    for (var p in _productos) {
      final precio = (p['precio'] ?? 0).toDouble();
      final cantidad = (p['cantidad'] ?? 1).toDouble();
      total += precio * cantidad;
    }
    return total;
  }

  Future<void> _eliminarProducto(String productoId) async {
    final response = await ApiService.removeFromCarrito(widget.usuarioId, productoId);
    if (response['success'] == true) {
      _cargarCarrito();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado del carrito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response['error'] ?? 'No se pudo eliminar'}')),
      );
    }
  }

  Future<void> _agregarUno(String productoId) async {
    final producto = _productos.firstWhere((p) => p['productoId'] == productoId, orElse: () => null);
    if (producto == null) return;

    final response = await ApiService.addToCarrito(widget.usuarioId, {
      'productoId': producto['productoId'],
      'nombre': producto['nombre'],
      'precio': producto['precio'],
      'cantidad': 1,
      'imagen': producto['imagen'],
    });
    if (response['success'] == true) {
      _cargarCarrito();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response['error'] ?? 'No se pudo aumentar la cantidad'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nombre = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCarrito,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _productos.isEmpty
                  ? const Center(child: Text('El carrito está vacío'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _productos.length,
                            itemBuilder: (context, index) {
                              final producto = _productos[index];
                              return ListTile(
                                leading: producto['imagen'] != null
                                    ? Image.network(producto['imagen'], width: 50, height: 50)
                                    : const Icon(Icons.image),
                                title: Text(producto['nombre'] ?? ''),
                                subtitle: Text('Cantidad: ${producto['cantidad']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('\$${producto['precio']}'),
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.red),
                                      onPressed: () => _eliminarProducto(producto['productoId']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.green),
                                      onPressed: () => _agregarUno(producto['productoId']),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${_total.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: ClienteNavBar(selectedIndex: 2, nombre: nombre),
    );
  }
}