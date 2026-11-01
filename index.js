// Importa o Express para criar o servidor
const express = require('express')
// Importa o Handlebars para criar páginas HTML dinâmicas
const exphbs = require('express-handlebars')
//const path = require('path');
// Cria a aplicação usando o Express
const app = express()
// Define a porta onde o servidor vai funcionar
const port = 3000
// Configura o Handlebars como mecanismo de visualização
app.engine('handlebars', exphbs.engine())
// Define o Handlebars como view engine do projeto
app.set('view engine', 'handlebars')
//Adiciona o CSS presente na pasta public
app.use(express.static('public'))

// Cria uma rota para a página inicial "/"
app.get('/', (req, res)=>{
    // Renderiza a página home e envia os dados para ela
    res.render('home')
})

app.get('/produto/:id', (req, res) => {
  
})

app.listen(port, ()=>{
    // Mostra uma mensagem no terminal quando o servidor iniciar
    console.log(`O servidor está rodando na porta ${port}`)
})