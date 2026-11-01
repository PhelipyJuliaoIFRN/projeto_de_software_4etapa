// Usa a conexão mysql/mysql2 com callbacks já criada no index.js.
module.exports = function registrarRestaurantes(app, conn) {
    const consultar = (sql, valores = []) => new Promise((resolve, reject) => {
        conn.query(sql, valores, (erro, dados) => erro ? reject(erro) : resolve(dados));
    });
    const moeda = valor => Number(valor).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
    function foto(valor) {
        if (typeof valor !== 'string') return null;
        const texto = valor.trim();
        if (/^\/(?!\/)/.test(texto) && !texto.includes('\\')) return texto;
        try { const url = new URL(texto); return ['https:', 'http:'].includes(url.protocol) ? url.href : null; }
        catch { return null; }
    }
    // Média e quantidade são calculadas a partir das avaliações reais.
    // Não reutilizamos as notas fictícias iniciais como se fossem comentários reais.
    const base = `SELECT r.rID, r.restaurante, r.foto_do_restaurante, r.descricao, r.filtro,
        (SELECT COUNT(*) FROM comidas c WHERE c.restaurante_cnpj = r.cnpj) AS total_produtos,
        (SELECT AVG(c.preco) FROM comidas c WHERE c.restaurante_cnpj = r.cnpj) AS preco_calculado,
        (SELECT AVG(a.nota) FROM avaliacoes_restaurantes a WHERE a.restaurante_cnpj = r.cnpj) AS media_real,
        (SELECT COUNT(*) FROM avaliacoes_restaurantes a WHERE a.restaurante_cnpj = r.cnpj) AS total_avaliacoes
        FROM restaurantes r`;
    function apresentar(r) {
        return {
            rID: r.rID, restaurante: r.restaurante, descricao: r.descricao,
            filtro: r.filtro, foto: foto(r.foto_do_restaurante),
            total_produtos: Number(r.total_produtos), total_avaliacoes: Number(r.total_avaliacoes),
            nota: r.media_real == null ? 'Sem avaliações' : Number(r.media_real).toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 }),
            preco: r.preco_calculado == null ? null : moeda(r.preco_calculado)
        };
    }
    function falha(res, view, erro) {
        console.error('Falha ao carregar restaurantes:', erro.code || erro.message);
        return res.status(500).render(view, { erro: 'Não foi possível carregar os dados. Tente novamente em instantes.', ocultarNavegacao: false });
    }
    app.get('/restaurantes', async (req, res) => {
        try {
            const busca = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 150) : '';
            // LOCATE faz busca literal; os parâmetros nunca são concatenados no SQL.
            const linhas = await consultar(base + ` WHERE (? = '' OR LOCATE(?, r.restaurante) > 0 OR LOCATE(?, r.filtro) > 0) ORDER BY r.restaurante`, [busca, busca, busca]);
            res.render('restaurantes', { restaurantes: linhas.map(apresentar), busca, quantidade: linhas.length, ocultarNavegacao: false });
        } catch (erro) { falha(res, 'restaurantes', erro); }
    });
    app.get('/restaurantes/:id', async (req, res) => {
        const id = Number(req.params.id);
        if (!/^\d+$/.test(req.params.id) || !Number.isSafeInteger(id) || id < 1 || id > 4294967295) {
            return res.status(404).render('restauranteDetalhe', { erro: 'Restaurante não encontrado.' });
        }
        try {
            const linhas = await consultar(base + ' WHERE r.rID = ?', [id]);
            if (!linhas.length) return res.status(404).render('restauranteDetalhe', { erro: 'Restaurante não encontrado.' });
            const produtos = await consultar(`SELECT c.pID, c.produto, c.descricao_do_produto, c.foto_do_produto,
                c.filtro, c.nota_media, c.tempo_de_espera, c.preco, c.desconto,
                ROUND(c.preco * (1 - c.desconto / 100), 2) AS preco_final
                FROM comidas c JOIN restaurantes r ON r.cnpj = c.restaurante_cnpj
                WHERE r.rID = ? ORDER BY c.filtro, c.produto`, [id]);
            const avaliacoes = await consultar(`SELECT a.nota, a.comentario,
                DATE_FORMAT(a.data_de_cadastro, '%d/%m/%Y') AS data,
                SUBSTRING_INDEX(TRIM(c.nome_completo), ' ', 1) AS autor
                FROM avaliacoes_restaurantes a
                JOIN clientes c ON c.cpf = a.cliente_cpf
                JOIN restaurantes r ON r.cnpj = a.restaurante_cnpj
                WHERE r.rID = ? ORDER BY a.data_de_cadastro DESC, a.aID DESC LIMIT 20`, [id]);
            const categorias = new Map();
            for (const p of produtos) {
                const nome = p.filtro || 'Outros';
                if (!categorias.has(nome)) categorias.set(nome, []);
                categorias.get(nome).push({
                    pID: p.pID, produto: p.produto, descricao: p.descricao_do_produto,
                    foto: foto(p.foto_do_produto), preco: moeda(p.preco_final),
                    preco_original: Number(p.desconto) > 0 ? moeda(p.preco) : null,
                    nota: p.nota_media == null ? 'Sem avaliações' : Number(p.nota_media).toLocaleString('pt-BR'),
                    tempo: p.tempo_de_espera
                });
            }
            res.render('restauranteDetalhe', {
                restaurante: apresentar(linhas[0]),
                grupos: [...categorias].map(([nome, itens], indice) => ({ nome, itens, ancora: `categoria-${indice}` })),
                avaliacoes: avaliacoes.map(a => ({ autor: a.autor, nota: a.nota, comentario: a.comentario, data: a.data })),
                ocultarNavegacao: false
            });
        } catch (erro) { falha(res, 'restauranteDetalhe', erro); }
    });
};
