# Registro de Viagens

Nome da temática do aplicativo: Registro de Viagens
Integrante 1: Gabriel Andrade
Integrante 2: Uriel
Integrante 3: Dimerson

## Descricao

Aplicativo Flutter para cadastrar viagens com destino, data e valor. O projeto
mantem os registros com SQLite local e tambem possui integracao preparada para
uma API propria em Node.js publicada no Render com PostgreSQL.

## Estrutura

- `lib/models`: modelo `Viagem`
- `lib/screens`: listagem e formulario
- `lib/components`: componentes reutilizaveis de interface
- `lib/db`: SQLite local
- `lib/services`: comunicacao HTTP com a API
- `lib/repository`: escolha entre persistencia local e remota
- `api`: API Express com PostgreSQL

## Rodando o app

```bash
flutter pub get
flutter run
```

Por padrao, o app usa SQLite local e tenta sincronizar pendencias quando ha
conexao com a API. Para usar a API remota, publique a pasta `api` no Render e
rode o Flutter passando a URL do Web Service:

```bash
flutter run --dart-define=API_BASE_URL=https://sua-api-no-render.onrender.com
```

No aplicativo, use o menu da AppBar para alternar entre `SQLite local` e
`API remota`.

Observacao: `api/.env` configura a conexao da API Node com o PostgreSQL. O app
Flutter nao le esse arquivo; por isso a URL HTTP da API deve ser informada com
`--dart-define=API_BASE_URL=...`.

## Rodando a API localmente

```bash
cd api
npm install
cp .env.example .env
npm run dev
```

Configure `DATABASE_URL` no `.env` com a URL do PostgreSQL.
