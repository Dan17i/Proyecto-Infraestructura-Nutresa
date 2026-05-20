const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const pool = new Pool({
  host: 'postgres',
  port: 5432,
  database: 'nutresadb',
  user: 'nutresa',
  password: 'Nutresa2026'
});

app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const result = await pool.query(
      'SELECT id, username, rol FROM usuarios WHERE username=$1 AND password=$2',
      [username, password]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }
    const user = result.rows[0];
    await pool.query(
      'INSERT INTO logs_acceso (usuario_id, accion) VALUES ($1, $2)',
      [user.id, 'login']
    );
    res.json({ message: 'Login exitoso', user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(3000, () => console.log('Backend corriendo en puerto 3000'));
