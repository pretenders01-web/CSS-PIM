using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela Clientes.
// A camada Modelos não referencia nenhum outro projeto da solução —
// ela é a base de tudo e não sabe que existe banco, web ou API.
public class Cliente
{
    public int Id { get; set; }

    // Validações básicas da própria entidade (tamanho, obrigatoriedade).
    // Regras que dependem do banco — como "e-mail não pode repetir" —
    // ficam na camada Negocio, não aqui.
    [Required, StringLength(100)]
    public string Nome { get; set; } = string.Empty;

    [Required, StringLength(150), EmailAddress]
    public string Email { get; set; } = string.Empty;

    // Só os 11 dígitos, sem ponto nem traço.
    [Required, StringLength(11, MinimumLength = 11)]
    public string Cpf { get; set; } = string.Empty;

    public DateTime DataCadastro { get; set; }

    // Preenchida pela trigger TR_Clientes_DataAtualizacao, não pelo C#.
    public DateTime? DataAtualizacao { get; set; }

    public bool Ativo { get; set; } = true;
}
