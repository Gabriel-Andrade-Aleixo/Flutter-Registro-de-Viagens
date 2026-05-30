const { Pool } = require('pg');

function getSslConfig() {
  if (process.env.PGSSLMODE === 'disable') {
    return false;
  }

  if (process.env.DATABASE_URL?.includes('localhost')) {
    return false;
  }

  return { rejectUnauthorized: false };
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: getSslConfig(),
});

async function initializeDatabase() {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL nao configurada.');
  }

  const host = new URL(process.env.DATABASE_URL).host;
  console.log(`[POSTGRES] Conectando em ${host}`);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS viagens (
      id SERIAL PRIMARY KEY,
      destino TEXT NOT NULL,
      data DATE NOT NULL,
      valor NUMERIC(10, 2) NOT NULL
    )
  `);

  console.log('[POSTGRES] Tabela viagens verificada/criada.');
}

module.exports = {
  pool,
  initializeDatabase,
};
