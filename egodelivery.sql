-- ============================================================
-- EgoDelivery | RECRIAÇÃO LIMPA para MySQL 8.0.16+
-- ATENÇÃO: apaga TODO o banco egodeliverydatabase e seus dados.
-- Execute este arquivo inteiro no MySQL Workbench, na ordem.
-- Pare na primeira falha. DROP/CREATE não são desfeitos por ROLLBACK.
-- O banco EgoDelivery, se existir separadamente, não é alterado.
-- ============================================================
DROP DATABASE IF EXISTS `egodeliverydatabase`;
CREATE DATABASE `egodeliverydatabase`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `egodeliverydatabase`;
SET NAMES utf8mb4;

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
CREATE TABLE restaurantes (
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
CREATE TABLE comidas (
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
CREATE TABLE entregadores (
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
CREATE TABLE clientes (
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
-- Nomes, documentos, e-mails, datas e produtos preservados do arquivo enviado.
-- Os CHECKs conferem formato, não autenticidade/dígitos verificadores.
-- Fotos permanecem NULL; a interface deve exibir um substituto.
-- Senhas dos clientes preservadas, agora armazenadas como hashes scrypt.
-- Restaurantes/entregadores recebem novas senhas aleatórias porque
-- os valores enviados eram hashes incompletos, sem senha recuperável.
-- Consulte credenciais_recriacao.txt para os acessos de demonstração.
-- A validação completa dos documentos/datas será feita no backend.
-- A transação abaixo cobre os dados, não a criação das tabelas.
-- Se a carga falhar, execute ROLLBACK em vez de COMMIT.
-- ============================================================
START TRANSACTION;

INSERT INTO restaurantes
    (restaurante, descricao, nota_media, filtro, cnpj, email, telefone, senha_hash)
VALUES
    ('Burger da Lua', 'Hambúrgueres artesanais e acompanhamentos preparados na hora.',
     4.70, 'Hamburgueria', '10056378000160', 'burgerdalua@gmail.com', '84900000001', 'scrypt$131072$8$1$466dff6878c2b2b9cd7eb4989109d1c3$338cf34949aa70d8c79b96ac9139cbef3880eca03a7d164a3a7782e0f9f1513b60c099106c985ee3ff5d384ec4b1ca527bca6a0292ecabc6e1355502f0c14827'),
    ('Pizza do Cometa', 'Pizzas de fermentação lenta com ingredientes selecionados.',
     4.80, 'Pizzaria', '16260546000111', 'pizzadocometa@gmail.com', '84900000002', 'scrypt$131072$8$1$cac10c7c411d24e284053fbf6b4154c1$e952824b21f994494daf7d976023c5192145a26dca016aff38213111e4102d458f9115aea08fc9fef8abfa2027b538e5963712a89cc83c7686ef0d81befc6a20'),
    ('Tempero do Sol', 'Comida caseira, opções vegetarianas e pratos regionais.',
     4.60, 'Comida brasileira', '05400342000112', 'temperodosol@gmail.com', '84900000003', 'scrypt$131072$8$1$ae921ea272abac785e31a954ba7cdfa4$a3ef70003db94d708a023fbfcf8df101aaa7322bc16fd7bbc2a04ef6e9a9af9eda5ac64caa4bbdd0e68e37418598c9ae5641bd48a366b077b97bd16fca9e08ba');

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
     'caio.entregador@gmail.com', '84900000004', 'scrypt$131072$8$1$bbe9b356096cf57fd34a28164a9f8d6b$66cbbfb10ec47be5d556f97ba02069b10d847eb9942c0ddb5b9191f4dbee663b2f0b4b992c0cd21aa8e72d0bdb94f4f4ac9165dd99a781d67349307cded5bb74'),
    ('Lara Melo de Teste', 4.80, '49247716357', '2000-09-23',
     'lara.entregadora@hotmail.com', '84900000005', 'scrypt$131072$8$1$c1ae8ddaa7d0f3d94c1597b2c613fc59$4bcb6e3d8bdb6c61ad9132cd435c627db5dc973c7653c3c9d4d8772c23f9bfcf8d92dc06d58da21193d247bd6270293af2e44075d779d09fc04cc614d0d14a16');

INSERT INTO clientes
    (nome_completo, cpf, data_de_nascimento, email, telefone, senha_hash)
VALUES
    ('Ana Lima da Silva Teste', '88761239208', '2001-02-15', 'anaTeste@outlook.com', '84900000006', 'scrypt$131072$8$1$347c0f74ecc4cd232c491dd62c42f6f5$05c9d6a3c70c6a6abe25618a28e0685c09f3e3af9a33c3752f3456ad04b80339977caf90b1801905b6fe1f243fa9d441e8819ec2f9c0ece31baab5fcf3ba82d2'),
    ('Bruno Costa Teste Filho', '30212876546', '2008-07-20', 'brunocstatestefilho_oficial@gmail.com', '84900000007', 'scrypt$131072$8$1$abae245363beac13112232c7a9469c27$41bd640153def6eb000f2192273f5af11a57689167e166bbbfd92131193b9558c1af7ed8d3c01dc480386b6ff967191310b09d9103a38f20c70a13571cd16634'),
    ('Clara Alves de Teste da Silva', '71642561525', '1973-11-08', 'claraAlves@yahoo.com', '84900000008', 'scrypt$131072$8$1$610b7bee2a7a7691f765b40b5b638c78$d29f7eb10b3a14ae7cddc0afffbbd6729f96017527e7493628547c31420e7cf6742b4f5a8fa6575bf2cc3b9c6552adfada1378bd99e0a16f0237988dfb4a600d'),
    ('Diego Rocha Costa Teste Neto', '07516441295', '1995-05-30', 'diegoPL22@gmail.com', '84900000009', 'scrypt$131072$8$1$9658a3f22cd5f4199263d87d9a572ea0$d5632fd80344cdd64d4d0bb2d6cc7e8b6cb7fe8c4b3a810e81efaae09f0c3896af139e2644b824c034e708b2070a4ea65f6b4fb77f4544e9bc679305f7f80f63'),
    ('Eva Martins do Teste Ribeiro', '33812434385', '1999-12-03', 'evafeminista@hotmail.com', '84900000010', 'scrypt$131072$8$1$8ac742eed98dff63b9cfbac8a578db35$908768ef4e7c6e9d359c89a52752bcb2d9a90fb93a6bd9cbbb9f71d2dcb609fb4ad0b9551f209b9980356213dcd0cee1214c00c79e7352b8b2e5d0e26af51f32');

-- Preenche a média inicial a partir dos produtos de cada restaurante.
-- Quando o cardápio mudar, o backend deverá recalcular esta média
-- na mesma transação da alteração, ou consultar AVG(preco) ao ler.
UPDATE restaurantes
SET preco_medio = (
    SELECT ROUND(AVG(preco), 2) FROM comidas
    WHERE restaurante_cnpj = '10056378000160'
)
WHERE cnpj = '10056378000160';

UPDATE restaurantes
SET preco_medio = (
    SELECT ROUND(AVG(preco), 2) FROM comidas
    WHERE restaurante_cnpj = '16260546000111'
)
WHERE cnpj = '16260546000111';

UPDATE restaurantes
SET preco_medio = (
    SELECT ROUND(AVG(preco), 2) FROM comidas
    WHERE restaurante_cnpj = '05400342000112'
)
WHERE cnpj = '05400342000112';

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

-- Confirma o banco ativo e as quatro tabelas criadas.
SELECT DATABASE() AS banco_ativo;
SHOW TABLES;