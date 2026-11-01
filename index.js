// Importa o Express para criar o servidor
const express = require('express');
// Importa o Handlebars para criar páginas HTML dinâmicas
const exphbs = require('express-handlebars');
// Importa o MySQL2 para integração com o banco de dados
const mysql = require('mysql2');
// Cria a aplicação usando o Express
const app = express();
// Define a porta onde o servidor vai funcionar
const port = 3000;
// Configura o Handlebars como mecanismo de visualização
app.engine('handlebars', exphbs.engine());
// Define o Handlebars como view engine do projeto
app.set('view engine', 'handlebars');
//Adiciona o CSS presente na pasta public
app.use(express.static('public'));
// Carrega as configurações locais antes de acessar process.env.
require("dotenv").config();

// Conexão com o banco: os dados vêm do arquivo .env.
const conn = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

// Cria uma rota para a página inicial "/"
app.get('/', (req, res) => {
    // Renderiza a página home e envia os dados para ela
    res.render('home')
});

//Caminho da página de cadastro
app.get('/signin', (req, res) => {
    res.render("signin",
        { ocultarNavegacao: true });
});

app.post('/signin/post', (req, res) => {

});

app.get('/login', (req, res)=>{
    res.render("login",
        { ocultarNavegacao: true}
    );
});

app.post('/login/post', (req, res) => {

});

// Registra o cardápio usando a conexão existente com o MySQL.
require("./routes/cardapio")(app, conn);

// Vitrine e páginas individuais dos restaurantes.
require("./routes/restaurantes")(app, conn);

// Exibe o cadastro do restaurante sem header e footer.
app.get("/restaurante/cadastro", (req, res) => {
    res.render("loginRestaurante",
        { ocultarNavegacao: true });
});

conn.connect((err)=>{
    if(err){
        console.log(err)
    }
    app.listen(port, ()=>{
        console.log(`O servidor está rodando na porta ${port}`)
    })
});