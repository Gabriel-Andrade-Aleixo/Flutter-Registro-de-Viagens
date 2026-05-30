require('dotenv').config();

const { initializeDatabase, pool } = require('./db');

initializeDatabase()
  .then(async () => {
    const result = await pool.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'viagens'
      ORDER BY ordinal_position
    `);

    console.log('Tabela viagens pronta.');
    console.table(result.rows);
  })
  .catch((error) => {
    console.error('Falha ao preparar banco de dados.', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
