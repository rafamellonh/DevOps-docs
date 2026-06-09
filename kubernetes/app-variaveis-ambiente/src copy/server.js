require('dotenv').config();
const express = require('express');
const app = express();
const port = 3000;

app.set("view engine", "ejs");

// Definindo variáveis de ambiente com valores padrão
const appName = process.env.APP_NAME;
const appVersion = process.env.APP_VERSION;
const appAuthor = process.env.APP_AUTHOR;

app.get('/', (req, res) => {
    res.render("index", {appName, appVersion, appAuthor});
});

app.listen(port, () => {
  console.log(`Aplicação ouvindo na porta ${port}`);
});
