using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA: o que o administrador PREENCHE para cadastrar ou alterar um setor.
// Não tem Id: no cadastro o banco gera; na alteração o id vem da URL.
public class SetorSalvarDto
{
    [Display(Name = "Estádio")]
    [Range(1, int.MaxValue, ErrorMessage = "Escolha o estádio.")]
    public int EstadioID { get; set; }

    [Display(Name = "Nome do setor")]
    [Required(ErrorMessage = "Informe o nome do setor.")]
    [StringLength(50, ErrorMessage = "O nome do setor pode ter no máximo 50 caracteres.")]
    public string NomeSetor { get; set; } = string.Empty;

    [Display(Name = "Capacidade")]
    [Range(1, int.MaxValue, ErrorMessage = "A capacidade deve ser maior que zero.")]
    public int Capacidade { get; set; }

    // A coluna é decimal(10,2): no máximo 99.999.999,99.
    [Display(Name = "Preço base")]
    [Range(0.0, 99999999.99, ErrorMessage = "O preço base deve estar entre 0 e 99.999.999,99.")]
    public decimal PrecoBase { get; set; }

    public Setor ParaSetor(int id = 0) => new()
    {
        SetorID = id,
        EstadioID = EstadioID,
        NomeSetor = NomeSetor,
        Capacidade = Capacidade,
        PrecoBase = PrecoBase
    };

    // Caminho inverso: preenche o formulário de edição com os dados atuais.
    public static SetorSalvarDto De(Setor s) => new()
    {
        EstadioID = s.EstadioID,
        NomeSetor = s.NomeSetor,
        Capacidade = s.Capacidade,
        PrecoBase = s.PrecoBase
    };
}
