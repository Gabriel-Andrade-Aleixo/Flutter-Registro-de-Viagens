# API Registro de Viagens

API propria em Node.js e Express para persistir viagens em PostgreSQL.

## Rotas

- `GET /viagens`: lista viagens
- `POST /viagens`: cadastra uma viagem
- `PUT /viagens/:id`: atualiza uma viagem
- `DELETE /viagens/:id`: remove uma viagem

Exemplo de JSON:

```json
{
  "destino": "Rio de Janeiro",
  "data": "2026-06-01T00:00:00.000Z",
  "valor": 850.5
}
```

## Criar tabelas

Depois de configurar `DATABASE_URL`, execute:

```bash
npm run db:init
```

## Render

1. Crie um PostgreSQL no Render.
2. Crie um Web Service apontando para a pasta `api`.
3. Configure `DATABASE_URL` com a connection string interna do PostgreSQL.
4. Use `npm install` como build command.
5. Use `npm start` como start command.

## Vercel

O projeto tambem esta preparado para hospedar a API na Vercel como uma Function.

1. Crie um novo projeto na Vercel apontando para este repositorio.
2. Em `Root Directory`, selecione `api`.
3. Configure a variavel de ambiente `DATABASE_URL`.
4. Use a External Database URL do PostgreSQL do Render, pois a Vercel nao acessa a rede interna do Render.
5. Faca o deploy normalmente.

Na Vercel, o Express fica em `api/index.js` e nao usa `app.listen()`. Localmente,
`npm run dev` continua usando `src/server.js`.

Depois do deploy, teste:

```text
https://sua-api.vercel.app/health
https://sua-api.vercel.app/viagens
```

## URLs do banco

- Rodando a API dentro do Render: use a Internal Database URL.
- Rodando a API no seu computador ou na Vercel: use a External Database URL.

Se usar a Internal Database URL fora do Render, o erro esperado e parecido com:

```text
getaddrinfo ENOTFOUND dpg-...
```
