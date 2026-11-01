// Compatível com conexões mysql/mysql2 que usam conn.query(sql, params, callback).
// Recebe a conexão existente: nenhuma credencial fica neste arquivo.
module.exports = function registrarCardapio(app, conn) {
    const moeda = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
    const icones = { 'hambúrguer': '🍔', pizza: '🍕', bebida: '🥤', acompanhamento: '🍟', vegetariano: '🥗', regional: '🍛', 'prato feito': '🍽️' };

    // Aceita caminhos públicos locais ou URLs HTTP(S) para fotos.
    function fotoSegura(valor) {
        if (typeof valor !== 'string') return null;
        const foto = valor.trim();
        if (/^\/(?!\/)/.test(foto) && !foto.includes('\\')) return foto;
        try { const url = new URL(foto); return ['http:', 'https:'].includes(url.protocol) ? url.href : null; }
        catch { return null; }
    }

    app.get('/cardapio', (req, res) => {
        // O link da página do restaurante limita a consulta ao seu rID.
        const valor = req.query.restaurante;
        const id = valor === undefined ? null : Number(valor);
        if (valor !== undefined && (typeof valor !== 'string' || !/^\d+$/.test(valor) || !Number.isSafeInteger(id) || id < 1 || id > 4294967295)) {
            return res.status(400).render('cardapio', { erro: 'Restaurante inválido.', comidas: [], categorias: [], quantidade: 0 });
        }
        const sql = `
            SELECT c.pID, c.produto, c.preco, c.foto_do_produto,
                   c.descricao_do_produto, c.tempo_de_espera, c.nota_media,
                   c.desconto, c.filtro, r.rID, r.restaurante,
                   CAST(ROUND(c.preco * (1 - c.desconto / 100), 2) * 100 AS UNSIGNED) AS preco_centavos
            FROM comidas AS c
            INNER JOIN restaurantes AS r ON r.cnpj = c.restaurante_cnpj
            ${id === null ? '' : 'WHERE r.rID = ?'}
            ORDER BY r.restaurante, c.produto`;

        conn.query(sql, id === null ? [] : [id], (erro, registros) => {
            if (erro) {
                // Não devolve detalhes da conexão/SQL ao navegador.
                console.error('Falha ao consultar cardápio:', erro.code);
                return res.status(500).render('cardapio', {
                    erro: 'Não foi possível carregar o cardápio. Tente novamente em instantes.',
                    comidas: [], categorias: [], quantidade: 0, ocultarNavegacao: false
                });
            }
            // Converte cada registro em objeto simples para o Handlebars.
            const comidas = registros.map(c => ({
                pID: c.pID, produto: c.produto, rID: c.rID, restaurante: c.restaurante,
                descricao_do_produto: c.descricao_do_produto || '',
                filtro: (c.filtro || '').trim(), tempo_de_espera: c.tempo_de_espera,
                foto_do_produto: fotoSegura(c.foto_do_produto),
                preco_centavos: Number(c.preco_centavos),
                preco_formatado: moeda.format(Number(c.preco_centavos) / 100),
                preco_original_formatado: moeda.format(Number(c.preco)),
                tem_desconto: Number(c.desconto) > 0,
                desconto_formatado: Number(c.desconto).toLocaleString('pt-BR'),
                nota_formatada: c.nota_media == null ? 'Sem avaliações' : Number(c.nota_media).toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 })
            }));
            const categorias = [...new Set(comidas.map(c => c.filtro).filter(Boolean))]
                .sort((a, b) => a.localeCompare(b, 'pt-BR'))
                .map(nome => ({ nome, icone: icones[nome.toLocaleLowerCase('pt-BR')] || '🍽️' }));
            res.render('cardapio', { comidas, categorias, quantidade: comidas.length, ocultarNavegacao: false });
        });
    });
};
