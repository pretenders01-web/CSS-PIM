using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA: o que o usuário PREENCHE para cadastrar ou alterar um estádio.
//   - A Api recebe este objeto no corpo do POST e do PUT.
//   - A Web usa este objeto nos formulários de Criar e Editar.
// Não tem Id: quem decide esse valor é o banco, não o usuário.
// As mensagens abaixo aparecem tanto embaixo do campo na tela quanto no 400 da Api.
public class EstadioSalvarDto
{
    [Display(Name = "Nome")]
    [Required(ErrorMessage = "Informe o nome.")]
    [StringLength(100, ErrorMessage = "O nome pode ter no máximo 100 caracteres.")]
    public string Nome { get; set; } = string.Empty;

    [Display(Name = "Cidade")]
    [Required(ErrorMessage = "Informe a cidade.")]
    [StringLength(100, ErrorMessage = "A cidade pode ter no máximo 100 caracteres.")]
    public string Cidade { get; set; } = string.Empty;

    [Display(Name = "Capacidade total")]
    [Range(1, int.MaxValue, ErrorMessage = "A capacidade deve ser maior que zero.")]
    public int CapacidadeTotal { get; set; }

    // Converte o que foi digitado na entidade que o Negocio entende.
    // No cadastro o id é 0 (o banco gera); na alteração vem da URL.
    public Estadio ParaEstadio(int id = 0) => new()
    {
        EstadioID = id,
        Nome = Nome,
        Cidade = Cidade,
        CapacidadeTotal = CapacidadeTotal
    };

    // Caminho inverso: preenche o formulário de edição com os dados atuais.
    public static EstadioSalvarDto De(Estadio e) => new()
    {
        Nome = e.Nome,
        Cidade = e.Cidade,
        CapacidadeTotal = e.CapacidadeTotal
    };
}
