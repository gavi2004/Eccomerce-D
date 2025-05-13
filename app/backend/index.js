const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const Usuario = require('./models/usuario'); // Importar el modelo centralizado
const loginRouter = require('./login');  // Asegúrate de importar el enrutador de login
const verificarToken = require('./middleware/auth'); // Importar el middleware de autenticación
const usersRouter = require('./routes/users'); // Importar el enrutador de usuarios

const app = express();
const PORT = 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Agregar esta línea
app.use('/users', usersRouter);

// Conectar a MongoDB
mongoose.connect('mongodb://localhost:27017/gestioner', {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('✅ Conectado a MongoDB'))
.catch(err => console.error('❌ Error conectando a MongoDB:', err));

// Obtener IP
function obtenerIP(req) {
  return req.headers['x-forwarded-for'] || req.socket.remoteAddress;
}

// Ruta de prueba
app.get('/ping', (req, res) => {
  const ip = obtenerIP(req);
  console.log(`📶 Nuevo dispositivo conectado desde: ${ip}`);
  res.json({ message: 'Conectado al backend', ip });
});

// Verificar si la cédula ya existe
app.get('/users/cedula/:cedula', async (req, res) => {
  try {
    const usuario = await Usuario.findOne({ cedula: req.params.cedula });
    if (usuario) {
      return res.status(200).json({ existe: true });
    } else {
      return res.status(404).json({ existe: false });
    }
  } catch (err) {
    console.error('❌ Error al verificar cédula:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Registrar usuario
app.post('/users', async (req, res) => {
  const { cedula, correo, nombre, telefono, contrasena, nivel } = req.body;

  if (!cedula || !correo || !nombre || !telefono || !contrasena) {
    return res.status(400).json({ error: 'Faltan campos obligatorios' });
  }

  try {
    const cedulaExistente = await Usuario.findOne({ cedula });
    if (cedulaExistente) {
      return res.status(409).json({ error: 'La cédula ya está registrada' });
    }

    const correoExistente = await Usuario.findOne({ correo });
    if (correoExistente) {
      return res.status(409).json({ error: 'El correo ya está registrado' });
    }

    const telefonoExistente = await Usuario.findOne({ telefono });
    if (telefonoExistente) {
      return res.status(409).json({ error: 'El teléfono ya está registrado' });
    }

    const nuevoUsuario = new Usuario({
      cedula, correo, nombre, telefono, contrasena, nivel
    });

    await nuevoUsuario.save();
    console.log('✅ Usuario guardado:', nuevoUsuario);
    res.status(201).json({ message: 'Usuario registrado correctamente' });
  } catch (err) {
    console.error('❌ Error al registrar usuario:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Usar el loginRouter para las rutas de login
app.use('/login', loginRouter);

app.use('/', usersRouter); // Montar el router de usuarios en la ruta base

// Ruta protegida (debe ir después de importar verificarToken)
app.get('/ruta-protegida', verificarToken, (req, res) => {
    res.json({ message: 'Acceso permitido', usuario: req.usuario });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});