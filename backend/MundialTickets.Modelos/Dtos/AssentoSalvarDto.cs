using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA: o que o administrador PREENCHE para cadastrar ou alterar um assento.
public class AssentoSalvarDto
{
    [Display(Name = "Setor")]
    [Range(1, int.MaxValue, ErrorMessage = "Escolha o setor.")]
    public int SetorID { get; set; }

    [Display(Name = "Número")]
    [Required(ErrorMessage = "Informe o número do assento.")]
    [StringLength(10, ErrorMessage = "O número pode ter no máximo 10 caracteres.")]
    public string Numero { get; set; } = string.Empty;

    public Assento ParaAssento(int id = 0) => new()
    {
        AssentoID = id,
        SetorID = SetorID,
        Numero = Numero
    };

    public static AssentoSalvarDto De(Assento a) => new()
    {
        SetorID = a.SetorID,
        Numero = a.Numero
    };
}
