// JavaScript do site. Só há dois comportamentos, e as páginas funcionam sem eles:
//   1) a barra de escolha de assentos (conta quantos foram marcados e liga o botão);
//   2) a confirmação antes de ações que não têm volta (excluir, desativar a conta).

document.addEventListener('DOMContentLoaded', function () {

    // ---- escolha de assentos ----
    var barra = document.querySelector('[data-barra-selecao]');
    if (barra) {
        var caixas = document.querySelectorAll('.assento-check:not(:disabled)');
        var contador = barra.querySelector('[data-contador]');
        var total = barra.querySelector('[data-total]');
        var botao = barra.querySelector('button[type="submit"]');

        var atualizar = function () {
            var marcados = Array.prototype.filter.call(caixas, function (c) { return c.checked; });
            var soma = marcados.reduce(function (acc, c) { return acc + parseFloat(c.dataset.preco || '0'); }, 0);
            if (contador) contador.textContent = marcados.length;
            if (total) total.textContent = soma.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
            if (botao) botao.disabled = marcados.length === 0;
        };
        caixas.forEach(function (c) { c.addEventListener('change', atualizar); });
        atualizar();
    }

    // ---- confirmação de ações sem volta ----
    document.querySelectorAll('form[data-confirmar]').forEach(function (form) {
        form.addEventListener('submit', function (evento) {
            if (!window.confirm(form.dataset.confirmar)) evento.preventDefault();
        });
    });
});
