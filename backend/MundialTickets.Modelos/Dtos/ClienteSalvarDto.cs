using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA: o que o usuário PREENCHE para cadastrar ou alterar um cliente.
//   - A Api recebe este objeto no corpo do POST e do PUT.
//   - A Web usa este objeto nos formulários de Criar e Editar.
// Não tem Id, DataCadastro nem DataAtualizacao: quem decide esses valores é o
// sistema, não o usuário. Se o DTO não tem o campo, ninguém consegue forjá-lo.
// As mensagens abaixo aparecem tanto embaixo do campo na tela quanto no 400 da Api.
public class ClienteSalvarDto
{
    [Display(Name = "Nome")]
    [Required(ErrorMessage = "Informe o nome.")]
    [StringLength(100, ErrorMessage = "O nome pode ter no máximo 100 caracteres.")]
    public string Nome { get; set; } = string.Empty;

    [Display(Name = "E-mail")]
    [Required(ErrorMessage = "Informe o e-mail.")]
    [StringLength(150, ErrorMessage = "O e-mail pode ter no máximo 150 caracteres.")]
    [EmailAddress(ErrorMessage = "E-mail inválido.")]
    public string Email { get; set; } = string.Empty;

    [Display(Name = "CPF")]
    [Required(ErrorMessage = "Informe o CPF.")]
    public string Cpf { get; set; } = string.Empty;

    [Display(Name = "Ativo")]
    public bool Ativo { get; set; } = true;

    // Converte o que foi digitado na entidade que o Negocio entende.
    // No cadastro o id é 0 (o banco gera); na alteração vem da URL.
    public Cliente ParaCliente(int id = 0) => new()
    {
        Id = id,
        Nome = Nome,
        Email = Email,
        Cpf = Cpf,
        Ativo = Ativo
    };

    // Caminho inverso: preenche o formulário de edição com os dados atuais.
    public static ClienteSalvarDto De(Cliente c) => new()
    {
        Nome = c.Nome,
        Email = c.Email,
        Cpf = c.Cpf,
        Ativo = c.Ativo
    };
}
