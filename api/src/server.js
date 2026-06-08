require('dotenv').config();

const { app, ensureDatabaseReady } = require('./app');

const port = process.env.PORT || 3000;

ensureDatabaseReady()
  .then(() => {
    const server = app.listen(port, () => {
      console.log(`API Registro de Viagens rodando na porta ${port}`);
    });

    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        console.error(
          `A porta ${port} ja esta em uso. Feche a outra API ou altere PORT no arquivo .env.`,
        );
        process.exit(1);
      }

      throw error;
    });
  })
  .catch((error) => {
    console.error('Falha ao inicializar banco de dados', error);
    process.exit(1);
  });
