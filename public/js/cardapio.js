/* Pesquisa e filtros sobre os produtos recebidos do MySQL.
   Carrinho temporário em memória: recarregar/sair da página o esvazia.
   A compra futura deverá validar preços e produtos novamente no servidor. */
(() => {
    const raiz = document.querySelector('.menu');
    if (!raiz) return;
    const $ = seletor => raiz.querySelector(seletor);
    const cards = [...raiz.querySelectorAll('[data-produto]')];
    const filtros = [...raiz.querySelectorAll('[data-filtro]')];
    const carrinho = new Map();
    const dinheiro = centavos => (centavos / 100).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
    const normalizar = valor => valor.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
    let categoria = '';

    // Mostra um substituto quando o caminho da foto existe, mas falha ao carregar.
    raiz.querySelectorAll('.menu-produto__foto img').forEach(img => {
        const falhou = () => { img.hidden = true; img.parentElement.querySelector('.menu-produto__sem-foto').hidden = false; };
        img.addEventListener('error', falhou);
        if (img.complete && !img.naturalWidth) falhou();
    });

    function filtrar() {
        const busca = normalizar($('#menu-busca').value.trim());
        let quantidade = 0;
        cards.forEach(card => {
            const texto = normalizar(`${card.dataset.nome} ${card.dataset.restaurante}`);
            const visivel = (!categoria || card.dataset.categoria === categoria) && texto.includes(busca);
            card.hidden = !visivel;
            if (visivel) quantidade++;
        });
        $('[data-resultado]').textContent = `${quantidade} produto${quantidade === 1 ? '' : 's'} encontrado${quantidade === 1 ? '' : 's'}`;
        $('[data-sem-resultados]').hidden = quantidade > 0;
    }
    $('[data-pesquisa]').addEventListener('submit', event => { event.preventDefault(); filtrar(); });
    $('#menu-busca').addEventListener('input', filtrar);
    filtros.forEach(botao => botao.addEventListener('click', () => {
        categoria = botao.dataset.filtro;
        filtros.forEach(filtro => filtro.setAttribute('aria-pressed', String(filtro === botao)));
        filtrar();
    }));
    $('[data-limpar-filtros]').addEventListener('click', () => {
        $('#menu-busca').value = '';
        filtros[0].click();
        $('#menu-busca').focus();
    });
    raiz.querySelectorAll('[data-direcao]').forEach(botao => botao.addEventListener('click', () => {
        $('[data-categorias]').scrollBy({ left: Number(botao.dataset.direcao) * 240, behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
    }));

    // Cria textos com textContent, sem interpretar nomes do banco como HTML.
    function elemento(tag, texto, classe) {
        const el = document.createElement(tag);
        el.textContent = texto;
        if (classe) el.className = classe;
        return el;
    }
    function mensagem(texto) { $('[data-mensagem]').textContent = texto; }
    function atualizarCarrinho(foco) {
        const lista = $('[data-itens]');
        lista.replaceChildren();
        let total = 0, quantidade = 0;
        carrinho.forEach(item => {
            total += item.centavos * item.quantidade;
            quantidade += item.quantidade;
            const li = elemento('li', '', 'menu-carrinho__item');
            li.append(elemento('strong', item.nome), elemento('span', dinheiro(item.centavos * item.quantidade)));
            const controles = elemento('div', '', 'menu-carrinho__controles');
            function botao(texto, acao, label) {
                const b = elemento('button', texto);
                b.type = 'button'; b.dataset.item = item.id; b.dataset.acao = acao;
                b.setAttribute('aria-label', `${label} ${item.nome}`);
                return b;
            }
            controles.append(botao('−', 'diminuir', 'Diminuir quantidade de'), elemento('span', String(item.quantidade)), botao('+', 'aumentar', 'Aumentar quantidade de'), botao('Remover', 'remover', 'Remover'));
            li.append(controles); lista.append(li);
        });
        $('[data-total]').textContent = dinheiro(total);
        $('[data-contagem]').textContent = quantidade;
        $('[data-carrinho-vazio]').hidden = quantidade > 0;
        $('[data-esvaziar]').disabled = quantidade === 0;
        $('[data-carrinho-restaurante]').textContent = carrinho.values().next().value?.restaurante || '';
        if (foco) {
            const destino = [...lista.querySelectorAll('button')].find(b => b.dataset.item === foco.id && b.dataset.acao === foco.acao) || lista.querySelector('button') || $('[data-adicionar]');
            if (destino) destino.focus();
        }
    }
    cards.forEach(card => card.querySelector('[data-adicionar]').addEventListener('click', () => {
        const d = card.dataset;
        const primeiro = carrinho.values().next().value;
        if (primeiro && primeiro.restauranteId !== d.restauranteId) {
            mensagem('Escolha produtos de um restaurante por vez. Esvazie o carrinho para trocar de restaurante.');
            return;
        }
        const item = carrinho.get(d.id) || { id: d.id, nome: d.nome, restaurante: d.restaurante, restauranteId: d.restauranteId, centavos: Number(d.centavos), quantidade: 0 };
        if (item.quantidade >= 99) { mensagem('Limite de 99 unidades por produto.'); return; }
        item.quantidade++; carrinho.set(d.id, item);
        atualizarCarrinho(); mensagem(`${item.nome} adicionado ao carrinho.`);
    }));
    $('[data-itens]').addEventListener('click', event => {
        const botao = event.target.closest('button[data-acao]');
        if (!botao) return;
        const item = carrinho.get(botao.dataset.item);
        if (!item) return;
        if (botao.dataset.acao === 'aumentar') {
            if (item.quantidade >= 99) { mensagem('Limite de 99 unidades por produto.'); return; }
            item.quantidade++;
        } else if (botao.dataset.acao === 'diminuir') item.quantidade--;
        else item.quantidade = 0;
        if (item.quantidade <= 0) carrinho.delete(item.id);
        atualizarCarrinho({ id: item.id, acao: botao.dataset.acao }); mensagem('Carrinho atualizado.');
    });
    $('[data-esvaziar]').addEventListener('click', () => {
        carrinho.clear(); atualizarCarrinho(); mensagem('Carrinho esvaziado.');
        $('[data-adicionar]')?.focus();
    });
})();
