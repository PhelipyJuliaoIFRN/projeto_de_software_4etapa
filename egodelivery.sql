-- ============================================================
-- EgoDelivery | Estrutura inicial e dados fictícios
-- Compatibilidade: MySQL 8.0.16 ou superior (inclui MySQL 8.4).
-- Execute em um banco de desenvolvimento com estas tabelas vazias.
-- Não há comandos para apagar tabelas ou registros existentes.
-- Execute a carga de exemplos uma única vez; uma segunda execução
-- encontrará documentos/e-mails repetidos e será rejeitada.
-- No editor SQL, interrompa a execução se ocorrer qualquer erro.
-- ============================================================

SET NAMES utf8mb4;

-- Se seu banco tiver outro nome, ajuste CREATE DATABASE e USE.
CREATE DATABASE IF NOT EXISTS EgoDelivery
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE EgoDelivery;

-- CONVENÇÕES
-- Nomes de colunas sem espaços/acentos simplificam o uso no JS.
-- rID, eID e cID são números automáticos e únicos para exibição.
-- Conforme solicitado, CNPJ/CPF continuam como chaves primárias.
-- Documentos e telefones são texto: podem começar com zero.
-- Telefones incluem DDD, sem espaços ou pontuação.
-- Fotos guardam somente URL ou caminho, por exemplo:
-- /image/hamburguer.jpg. O arquivo fica em public/image no site.
-- NULL nas fotos significa que o site deve usar uma imagem padrão.
-- Notas vão de 0 a 5; NULL significa que ainda não há avaliação.
-- Filtro representa uma categoria única nesta versão inicial.
-- Senha_hash deve receber um hash gerado pelo backend, nunca
-- a senha em texto puro. NULL indica conta sem senha configurada.
-- O login deve recusar contas cujo senha_hash seja NULL.
-- Hashes de exemplo usam scrypt, disponível no módulo crypto do Node.js.
-- Formato: scrypt$N$r$p$salt_hex$hash_hex
-- N=131072, r=8, p=1; salt de 16 bytes; chave de 64 bytes.
-- No Node, decodifique salt/hash com Buffer.from(valor, "hex"),
-- use crypto.scrypt com maxmem=268435456 e compare o resultado
-- com crypto.timingSafeEqual. Não use bcrypt.compare nestes hashes.

-- ============================================================
-- 1. RESTAURANTES
-- Um restaurante pode ter várias comidas.
-- ============================================================
CREATE TABLE IF NOT EXISTS restaurantes (
    rID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    restaurante VARCHAR(150) NOT NULL,
    foto_do_restaurante VARCHAR(500) NULL,
    descricao TEXT NULL,
    preco_medio DECIMAL(10,2) NULL COMMENT 'Reais; média dos preços do cardápio sem desconto',
    nota_media DECIMAL(3,2) NULL,
    filtro VARCHAR(80) NOT NULL,
    data_de_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cnpj CHAR(14) NOT NULL,
    email VARCHAR(254) NOT NULL,
    telefone VARCHAR(11) NOT NULL COMMENT 'DDD + número: 10 ou 11 dígitos',
    senha_hash VARCHAR(255) NULL,

    PRIMARY KEY (cnpj),
    UNIQUE KEY uq_restaurantes_rid (rID),
    UNIQUE KEY uq_restaurantes_email (email),
    KEY idx_restaurantes_filtro (filtro),
    CONSTRAINT chk_restaurantes_cnpj CHECK (CHAR_LENGTH(cnpj) = 14),
    CONSTRAINT chk_restaurantes_telefone CHECK (telefone REGEXP '^[0-9]{10,11}$'),
    CONSTRAINT chk_restaurantes_preco CHECK (preco_medio >= 0),
    CONSTRAINT chk_restaurantes_nota CHECK (nota_media BETWEEN 0 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- 2. COMIDAS
-- restaurante_cnpj identifica o restaurante dono do produto.
-- O nome do restaurante é consultado com JOIN, sem duplicá-lo.
-- RESTRICT impede excluir um restaurante que ainda tem comidas.
-- CASCADE atualiza a referência se o CNPJ for corrigido.
-- ============================================================
CREATE TABLE IF NOT EXISTS comidas (
    pID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    produto VARCHAR(150) NOT NULL,
    preco DECIMAL(10,2) NOT NULL COMMENT 'Preço original em reais',
    foto_do_produto VARCHAR(500) NULL,
    descricao_do_produto TEXT NULL,
    restaurante_cnpj CHAR(14) NOT NULL,
    tempo_de_espera SMALLINT UNSIGNED NOT NULL COMMENT 'Estimativa em minutos',
    nota_media DECIMAL(3,2) NULL,
    desconto DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Percentual: 10.00 significa 10%',
    filtro VARCHAR(80) NOT NULL,
    data_de_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (pID),
    KEY idx_comidas_restaurante (restaurante_cnpj),
    KEY idx_comidas_filtro (filtro),
    CONSTRAINT fk_comidas_restaurante
        FOREIGN KEY (restaurante_cnpj) REFERENCES restaurantes (cnpj)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_comidas_preco CHECK (preco >= 0),
    CONSTRAINT chk_comidas_nota CHECK (nota_media BETWEEN 0 AND 5),
    CONSTRAINT chk_comidas_desconto CHECK (desconto BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- 3. ENTREGADORES
-- O vínculo com cliente/restaurante será feito por pedidos quando
-- o fluxo de compras for implementado. Um entregador pode atender
-- vários restaurantes; não deve ficar preso a um único cadastro.
-- ============================================================
CREATE TABLE IF NOT EXISTS entregadores (
    eID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome_completo VARCHAR(150) NOT NULL,
    foto_do_entregador VARCHAR(500) NULL,
    nota_media DECIMAL(3,2) NULL,
    data_de_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cpf CHAR(11) NOT NULL,
    data_de_nascimento DATE NOT NULL,
    email VARCHAR(254) NOT NULL,
    telefone VARCHAR(11) NOT NULL,
    senha_hash VARCHAR(255) NULL,

    PRIMARY KEY (cpf),
    UNIQUE KEY uq_entregadores_eid (eID),
    UNIQUE KEY uq_entregadores_email (email),
    CONSTRAINT chk_entregadores_cpf CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT chk_entregadores_telefone CHECK (telefone REGEXP '^[0-9]{10,11}$'),
    CONSTRAINT chk_entregadores_nota CHECK (nota_media BETWEEN 0 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- 4. CLIENTES
-- Um cliente pode comprar de diferentes restaurantes.
-- Não existe vínculo fixo de cliente com restaurante/entregador.
-- O e-mail é único dentro de cada tabela de contas.
-- ============================================================
CREATE TABLE IF NOT EXISTS clientes (
    cID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome_completo VARCHAR(150) NOT NULL,
    foto_do_cliente VARCHAR(500) NULL,
    data_de_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cpf CHAR(11) NOT NULL,
    data_de_nascimento DATE NOT NULL,
    email VARCHAR(254) NOT NULL,
    telefone VARCHAR(11) NOT NULL,
    senha_hash VARCHAR(255) NULL,

    PRIMARY KEY (cpf),
    UNIQUE KEY uq_clientes_cid (cID),
    UNIQUE KEY uq_clientes_email (email),
    CONSTRAINT chk_clientes_cpf CHECK (cpf REGEXP '^[0-9]{11}$'),
    CONSTRAINT chk_clientes_telefone CHECK (telefone REGEXP '^[0-9]{10,11}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- 5. DADOS FICTÍCIOS
-- Os documentos abaixo são marcadores de teste, sem validação de
-- dígitos verificadores. Não representam documentos reais válidos.
-- Datas, nomes, notas e telefones também são dados de demonstração.
-- E-mails usam example.com; fotos ficam NULL. As contas possuem
-- senhas aleatórias de teste, listadas em credenciais_teste.txt.
-- A validação completa dos documentos/datas será feita no backend.
-- A transação abaixo cobre os dados, não a criação das tabelas.
-- Se a carga falhar, execute ROLLBACK em vez de COMMIT.
-- ============================================================
START TRANSACTION;

INSERT INTO restaurantes
    (restaurante, descricao, nota_media, filtro, cnpj, email, telefone, senha_hash)
VALUES
    ('Burger da Lua', 'Hambúrgueres artesanais e acompanhamentos preparados na hora.',
     4.70, 'Hamburgueria', '10056378000160', 'burgerdalua@gmail.com', '84900000001', 'scrypt$131072$8$'),
    ('Pizza do Cometa', 'Pizzas de fermentação lenta com ingredientes selecionados.',
     4.80, 'Pizzaria', '16260546000111', 'pizzadocometa@gmail.com', '84900000002', 'scrypt$131072$8$1$'),
    ('Tempero do Sol', 'Comida caseira, opções vegetarianas e pratos regionais.',
     4.60, 'Comida brasileira', '05400342000112', 'temperodosol@gmail.com', '84900000003', 'scrypt$131072$8$1$');

INSERT INTO comidas
    (produto, preco, descricao_do_produto, restaurante_cnpj,
     tempo_de_espera, nota_media, desconto, filtro)
VALUES
    ('Burger Lunar', 25.90, 'Pão brioche, hambúrguer bovino, queijo e molho da casa.',
     '10056378000160', 30, 4.80, 10.00, 'Hambúrguer'),
    ('Burger Eclipse', 32.90, 'Dois hambúrgueres bovinos, cheddar e cebola caramelizada.',
     '10056378000160', 35, 4.90, 0.00, 'Hambúrguer'),
    ('Batata Estelar', 14.90, 'Porção de batatas fritas com páprica e molho da casa.',
     '10056378000160', 20, 4.50, 5.00, 'Acompanhamento'),
    ('Suco de Maracujá', 8.00, 'Suco de maracujá preparado na hora, copo de 300 ml.',
     '10056378000160', 10, 4.60, 0.00, 'Bebida'),
    ('Pizza Calabresa Cósmica', 45.90, 'Pizza com molho de tomate, muçarela, calabresa e cebola.',
     '16260546000111', 45, 4.80, 10.00, 'Pizza'),
    ('Pizza Marguerita Solar', 42.90, 'Pizza com molho de tomate, muçarela, tomate e manjericão.',
     '16260546000111', 40, 4.70, 0.00, 'Pizza'),
    ('Pizza Quatro Queijos', 49.90, 'Pizza com muçarela, provolone, parmesão e gorgonzola.',
     '16260546000111', 45, 4.90, 15.00, 'Pizza'),
    ('Prato da Casa', 22.00, 'Arroz, feijão, frango grelhado e salada.',
     '05400342000112', 25, 4.60, 0.00, 'Prato feito'),
    ('Baião de Dois', 28.00, 'Arroz, feijão-verde, queijo coalho e carne de sol.',
     '05400342000112', 30, 4.80, 5.00, 'Regional'),
    ('Bowl Vegetariano', 24.00, 'Arroz integral, grão-de-bico, legumes assados e folhas.',
     '05400342000112', 25, 4.50, 0.00, 'Vegetariano');

INSERT INTO entregadores
    (nome_completo, nota_media, cpf, data_de_nascimento, email, telefone, senha_hash)
VALUES
    ('Caio Nunes de Teste', 4.90, '28048764709', '1998-04-12',
     'caio.entregador@gmail.com', '84900000004', 'scrypt$131072$8$1$'),
    ('Lara Melo de Teste', 4.80, '49247716357', '2000-09-23',
     'lara.entregadora@hotmail.com', '84900000005', 'scrypt$131072$8$1');

INSERT INTO clientes
    (nome_completo, cpf, data_de_nascimento, email, telefone, senha_hash)
VALUES
    ('Ana Lima da Silva Teste', '88761239208', '2001-02-15', 'anaTeste@outlook.com', '84900000006', 'Ana@132'),
    ('Bruno Costa Teste Filho', '30212876546', '2008-07-20', 'brunocstatestefilho_oficial@gmail.com', '84900000007', 'BruNo.Coin$%<3---UwU'),
    ('Clara Alves de Teste da Silva', '71642561525', '1973-11-08', 'claraAlves@yahoo.com', '84900000008', '!@#asd-CLARA$1973'),
    ('Diego Rocha Costa Teste Neto', '07516441295', '1995-05-30', 'diegoPL22@gmail.com', '84900000009', '#DeusPatriaEFamilia'),
    ('Eva Martins do Teste Ribeiro', '33812434385', '1999-12-03', 'evafeminista@hotmail.com', '84900000010', '@Deus+Criou%Adao$e#EVA-lula13');

-- Preenche a média inicial a partir dos produtos de cada restaurante.
-- Quando o cardápio mudar, o backend deverá recalcular esta média
-- na mesma transação da alteração, ou consultar AVG(preco) ao ler.
UPDATE restaurantes AS r
SET preco_medio = (
    SELECT ROUND(AVG(c.preco), 2)
    FROM comidas AS c
    WHERE c.restaurante_cnpj = r.cnpj
);

COMMIT;

-- ============================================================
-- 6. CONSULTAS PARA CONFERIR E USAR COMO BASE NO SITE
-- ============================================================

-- Em um banco inicialmente vazio: 3 restaurantes, 10 comidas,
-- 2 entregadores e 5 clientes.
SELECT 'restaurantes' AS tabela, COUNT(*) AS quantidade FROM restaurantes
UNION ALL SELECT 'comidas', COUNT(*) FROM comidas
UNION ALL SELECT 'entregadores', COUNT(*) FROM entregadores
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes;

-- Cardápio: o JOIN traz o nome do restaurante relacionado à comida.
-- O desconto é percentual e o preço final é calculado na consulta.
SELECT
    c.pID,
    c.produto,
    c.preco,
    c.foto_do_produto,
    c.descricao_do_produto,
    r.rID,
    r.restaurante,
    c.tempo_de_espera,
    c.nota_media,
    c.desconto,
    ROUND(c.preco * (1 - c.desconto / 100), 2) AS preco_final,
    c.filtro,
    c.data_de_cadastro
FROM comidas AS c
INNER JOIN restaurantes AS r ON r.cnpj = c.restaurante_cnpj
ORDER BY r.restaurante, c.produto;

-- Listagem pública: selecione apenas os campos necessários à tela.
SELECT rID, restaurante, foto_do_restaurante, descricao,
       preco_medio, nota_media, filtro
FROM restaurantes
ORDER BY restaurante;

-- Próxima etapa, quando houver compras:
-- pedidos: cliente, restaurante, entregador (opcional até atribuir),
--          status, endereço de entrega e valores da compra.
-- itens_pedido: pedido, comida, quantidade e preço na hora da compra.
-- Essas tabelas permitirão relacionar as contas por cada pedido,
-- mantendo o histórico mesmo quando os preços do cardápio mudarem.
