# Ego Delivery 🍔🚀

Projeto de desenvolvimento de interface para uma aplicação de delivery de comida, desenvolvido para a disciplina de **Projeto de Desenvolvimento de Software**.

---

## 👥 Equipe — Grupo G4

* **João Gabryel**
* **Renato**
* **Joan**
* **Murylo**
* **Phelype**

📌 **Modelo de Desenvolvimento Adotado:** Incremental  

---

## 🛠️ Tecnologias Utilizadas

- **Node.js**: Ambiente de execução para o servidor.
- **Express.js**: Framework backend para roteamento e gerenciamento de requisições.
- **Handlebars (`express-handlebars`)**: Template engine para renderização das telas dinâmicas.
- **HTML5 & CSS3**: Estruturação semântica e estilização visual das interfaces.

---

## 📐 Estrutura das Telas e Requisitos do Projeto

O projeto contempla a criação das telas essenciais para a plataforma de delivery, atendendo aos requisitos da atividade:

1. **Tela Principal (Landing Page) — `home.handlebars`**
   - Logo e nome do aplicativo (**Ego Delivery**).
   - Barra de navegação funcional (4 itens de menu).
   - Rodapé com informações de contato e mais 3 informações relevantes.

2. **Tela de Login — `login.handlebars`**
   - Campos: **CPF**, **Senha** e opção **"Esqueceu a senha"**.

3. **Tela de Cadastro — `signin.handlebars`**
   - Campos: **Nome**, **Data de Nascimento**, **CPF**, **Senha**, **Confirmação de Senha**, **Tipo do Usuário** (*Cliente, Restaurante, Entregador*) e **Endereço**.

4. **Telas Complementares:**
   - **Cardápio (`cardapio.handlebars`)**: Exibição dos itens disponíveis.
   - **Detalhes do Produto (`produtoID.handlebars`)**: Visualização detalhada de um item.
   - **Restaurantes (`restaurantes.handlebars`)**: Listagem dos estabelecimentos parceiros.
   - **Sobre Nós (`sobreNos.handlebars`)**: Informações institucionais.

---

## 📂 Estrutura de Pastas

```text
PROJETO_DE_SOFTWARE_4ETAPA/
├── node_modules/
├── public/
│   ├── css/
│   │   └── style.css
│   └── image/
├── views/
│   ├── layouts/
│   │   └── main.handlebars
│   ├── cardapio.handlebars
│   ├── home.handlebars
│   ├── login.handlebars
│   ├── produtoID.handlebars
│   ├── restaurantes.handlebars
│   ├── signin.handlebars
│   └── sobreNos.handlebars
├── .gitignore
├── index.js
├── package.json
└── package-lock.json
```

---

## 🚀 Como Executar o Projeto

1. **Clone o repositório:**
   ```bash
   git clone <URL_DO_SEU_REPOSITORIO>
   ```

2. **Acesse a pasta do projeto:**
   ```bash
   cd PROJETO_DE_SOFTWARE_4ETAPA
   ```

3. **Instale as dependências:**
   ```bash
   npm install
   ```

4. **Inicie o servidor:**
   ```bash
   npm start
   # ou
   node index.js
   ```

5. **Acesse no navegador:**
   ```text
   http://localhost:3000
   ```

---

*Trabalho desenvolvido para a disciplina de Projeto de Desenvolvimento de Software.*