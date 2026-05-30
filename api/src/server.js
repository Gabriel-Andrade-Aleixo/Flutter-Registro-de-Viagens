require('dotenv').config();

const cors = require('cors');
const express = require('express');
const { initializeDatabase, pool } = require('./db');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
  console.log(`[API] ${req.method} ${req.originalUrl}`);
  next();
});

app.get('/', (req, res) => {
  res.json({ mensagem: 'API Registro de Viagens online' });
});

app.get('/viagens', async (req, res, next) => {
  try {
    console.log('[API] Listando viagens no PostgreSQL.');
    const result = await pool.query(
      'SELECT id, destino, data, valor FROM viagens ORDER BY data DESC, id DESC',
    );
    console.log(`[API] Viagens retornadas: ${result.rowCount}`);
    res.json(result.rows.map(formatarViagem));
  } catch (error) {
    next(error);
  }
});

app.post('/viagens', async (req, res, next) => {
  try {
    console.log('[API] Body recebido no POST /viagens:', req.body);
    const { destino, data, valor } = validarViagem(req.body);
    const result = await pool.query(
      'INSERT INTO viagens (destino, data, valor) VALUES ($1, $2, $3) RETURNING id, destino, data, valor',
      [destino, data, valor],
    );

    console.log(`[API] Viagem inserida no PostgreSQL com id=${result.rows[0].id}`);
    res.status(201).json(formatarViagem(result.rows[0]));
  } catch (error) {
    next(error);
  }
});

app.put('/viagens/:id', async (req, res, next) => {
  try {
    console.log(`[API] Body recebido no PUT /viagens/${req.params.id}:`, req.body);
    const id = Number(req.params.id);
    const { destino, data, valor } = validarViagem(req.body);

    if (!Number.isInteger(id)) {
      return res.status(400).json({ erro: 'Id invalido.' });
    }

    const result = await pool.query(
      'UPDATE viagens SET destino = $1, data = $2, valor = $3 WHERE id = $4 RETURNING id, destino, data, valor',
      [destino, data, valor, id],
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Viagem nao encontrada.' });
    }

    console.log(`[API] Viagem atualizada no PostgreSQL id=${id}`);
    return res.json(formatarViagem(result.rows[0]));
  } catch (error) {
    return next(error);
  }
});

app.delete('/viagens/:id', async (req, res, next) => {
  try {
    console.log(`[API] Excluindo viagem id=${req.params.id}`);
    const id = Number(req.params.id);

    if (!Number.isInteger(id)) {
      return res.status(400).json({ erro: 'Id invalido.' });
    }

    const result = await pool.query('DELETE FROM viagens WHERE id = $1', [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ erro: 'Viagem nao encontrada.' });
    }

    console.log(`[API] Viagem excluida do PostgreSQL id=${id}`);
    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
});

app.use((error, req, res, next) => {
  console.error(`[API] Erro em ${req.method} ${req.originalUrl}:`, error);

  if (error.statusCode) {
    return res.status(error.statusCode).json({ erro: error.message });
  }

  return res.status(500).json({ erro: 'Erro interno no servidor.' });
});

function validarViagem(body) {
  const destino = String(body.destino || '').trim();
  const data = String(body.data || '').slice(0, 10);
  const valor = Number(body.valor);

  if (!destino || Number.isNaN(Date.parse(data)) || Number.isNaN(valor)) {
    const error = new Error('Informe destino, data e valor validos.');
    error.statusCode = 400;
    throw error;
  }

  return { destino, data, valor };
}

function formatarViagem(row) {
  return {
    id: row.id,
    destino: row.destino,
    data: new Date(row.data).toISOString(),
    valor: Number(row.valor),
  };
}

initializeDatabase()
  .then(() => {
    app.listen(port, () => {
      console.log(`API Registro de Viagens rodando na porta ${port}`);
    });
  })
  .catch((error) => {
    console.error('Falha ao inicializar banco de dados', error);
    process.exit(1);
  });
