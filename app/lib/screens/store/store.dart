import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api_service.dart';
import '../../widgets/client_navbar.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<dynamic> _productos = [];
  List<dynamic> _productosFiltrados = [];
  bool _isLoading = true;
  String _error = '';
  final TextEditingController _searchController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Filtros adicionales
  String _filtroCategoria = '';
  String _filtroMarca = '';
  double _precioMin = 0;
  double _precioMax = 0;
  double _precioSeleccionadoMin = 0;
  double _precioSeleccionadoMax = 0;

  List<String> _categorias = [];
  List<String> _marcas = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final response = await ApiService.getProducts();
      if (response['success']) {
        final productos = response['productos'];
        // Obtener categorías y marcas únicas
        _categorias = productos.map<String>((p) => p['categoria'] as String).toSet().toList();
        _marcas = productos.map<String>((p) => p['marca'] as String).toSet().toList();
        // Calcular precios min y max
        final precios = productos.map<double>((p) => (p['precio'] as num).toDouble()).toList();
        _precioMin = precios.isEmpty ? 0 : precios.reduce((double a, double b) => a < b ? a : b);
        _precioMax = precios.isEmpty ? 0 : precios.reduce((double a, double b) => a > b ? a : b);
        _precioSeleccionadoMin = _precioMin;
        _precioSeleccionadoMax = _precioMax;
        setState(() {
          _productos = productos;
          _productosFiltrados = productos;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Error al cargar productos';
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

  void _filtrarProductos(String query) {
    setState(() {
      _productosFiltrados = _productos.where((producto) {
        final nombre = producto['nombre'].toString().toLowerCase();
        final categoria = producto['categoria'].toString().toLowerCase();
        final marca = producto['marca'].toString().toLowerCase();
        final precio = (producto['precio'] as num).toDouble();

        final coincideNombre = nombre.contains(query.toLowerCase());
        final coincideCategoria = _filtroCategoria.isEmpty || categoria == _filtroCategoria.toLowerCase();
        final coincideMarca = _filtroMarca.isEmpty || marca == _filtroMarca.toLowerCase();
        final coincidePrecio = precio >= _precioSeleccionadoMin && precio <= _precioSeleccionadoMax;

        return coincideNombre && coincideCategoria && coincideMarca && coincidePrecio;
      }).toList();
    });
  }

  void _onCategoriaChanged(String? value) {
    setState(() {
      _filtroCategoria = value ?? '';
    });
    _filtrarProductos(_searchController.text);
  }

  void _onMarcaChanged(String? value) {
    setState(() {
      _filtroMarca = value ?? '';
    });
    _filtrarProductos(_searchController.text);
  }

  void _onPrecioChanged(RangeValues values) {
    setState(() {
      _precioSeleccionadoMin = values.start;
      _precioSeleccionadoMax = values.end;
    });
    _filtrarProductos(_searchController.text);
  }

  Future<void> _agregarAlCarrito(Map<String, dynamic> producto) async {
    final usuarioId = await _storage.read(key: 'usuario_id');
    if (usuarioId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el usuario. Inicia sesión de nuevo.')),
        );
      }
      return;
    }
    final response = await ApiService.addToCarrito(usuarioId, {
      'productoId': producto['productoId'] ?? producto['id'] ?? producto['_id'],
      'nombre': producto['nombre'],
      'precio': producto['precio'],
      'cantidad': 1,
      'imagen': producto['imagen'],
    });
    if (response['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto añadido al carrito')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['error'] ?? 'No se pudo añadir al carrito'}')),
        );
      }
    }
  }

  void _mostrarDetallesProducto(Map<String, dynamic> producto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (producto['imagen'] != null)
                Center(
                  child: Image.network(
                    producto['imagen'],
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                producto['nombre'] ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                producto['marca'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                producto['descripcion'] ?? 'Sin descripción',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                '\$${producto['precio'].toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _agregarAlCarrito(producto);
                    Navigator.pop(context);
                  },
                  child: const Text('Agregar al carrito'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _reiniciarFiltros() {
    setState(() {
      _searchController.clear();
      _filtroCategoria = '';
      _filtroMarca = '';
      _precioSeleccionadoMin = _precioMin;
      _precioSeleccionadoMax = _precioMax;
    });
    _filtrarProductos('');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nombre = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            centerTitle: false,
            backgroundColor: colorScheme.primary,
            title: Text('Tienda', 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimary
              )
            ),
            bottom: AppBar(
              backgroundColor: colorScheme.primary,
              title: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filtrarProductos,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, color: colorScheme.primary),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarProductos('');
                        },
                      ),
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Container()), // Espacio para alinear el botón a la derecha
                      ElevatedButton.icon(
                        onPressed: _reiniciarFiltros,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reiniciar filtros'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Filtro por categoría
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filtroCategoria.isEmpty ? null : _filtroCategoria,
                          hint: const Text('Categoría'),
                          items: _categorias.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          )).toList(),
                          onChanged: _onCategoriaChanged,
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filtro por marca
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filtroMarca.isEmpty ? null : _filtroMarca,
                          hint: const Text('Marca'),
                          items: _marcas.map((marca) => DropdownMenuItem(
                            value: marca,
                            child: Text(marca),
                          )).toList(),
                          onChanged: _onMarcaChanged,
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Filtro por intervalo de precio
                  Row(
                    children: [
                      const Text('Precio:'),
                      Expanded(
                        child: RangeSlider(
                          min: _precioMin,
                          max: _precioMax,
                          divisions: (_precioMax - _precioMin).toInt() > 0 ? (_precioMax - _precioMin).toInt() : 1,
                          values: RangeValues(_precioSeleccionadoMin, _precioSeleccionadoMax),
                          labels: RangeLabels(
                            '\$${_precioSeleccionadoMin.toStringAsFixed(0)}',
                            '\$${_precioSeleccionadoMax.toStringAsFixed(0)}',
                          ),
                          onChanged: (values) => _onPrecioChanged(values),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Favoritos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: Center(child: Text(_error)),
            )
          else if (_productosFiltrados.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No se encontraron productos',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final producto = _productosFiltrados[index];
                    return GestureDetector(
                      onTap: () => _mostrarDetallesProducto(producto),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  producto['imagen'] != null
                                    ? Image.network(
                                        producto['imagen'],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: colorScheme.surfaceVariant,
                                            child: Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: colorScheme.surfaceVariant,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: colorScheme.surfaceVariant,
                                        child: Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 50,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.favorite_border,
                                        color: colorScheme.primary,
                                      ),
                                      onPressed: () {
                                        _mostrarDetallesProducto(producto);
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.surface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto['marca'],
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    producto['nombre'],
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${producto['precio'].toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _productosFiltrados.length,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: ClienteNavBar(selectedIndex: 1, nombre: nombre),
    );
  }
}