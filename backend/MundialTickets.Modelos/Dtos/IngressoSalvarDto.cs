using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA: o que o administrador PREENCHE para cadastrar ou alterar um ingresso.
// Não tem Status nem NumeroAssento: o status segue regras do Negocio (cancelar, vender) e o
// número do assento é copiado do próprio assento escolhido.
public class IngressoSalvarDto
{
    [Display(Name = "Jogo")]
    [Range(1, int.MaxValue, ErrorMessage = "Escolha o jogo.")]
    public int JogoID { get; set; }

    [Display(Name = "Setor")]
    [Range(1, int.MaxValue, ErrorMessage = "Escolha o setor.")]
    public int SetorID { get; set; }

    // O sistema vende por assento escolhido, então o assento é obrigatório aqui,
    // embora o banco aceite ingresso sem assento.
    [Display(Name = "Assento")]
    [Range(1, int.MaxValue, ErrorMessage = "Escolha o assento.")]
    public int AssentoID { get; set; }

    // A coluna é decimal(10,2): no máximo 99.999.999,99.
    [Display(Name = "Preço")]
    [Range(0.0, 99999999.99, ErrorMessage = "O preço deve estar entre 0 e 99.999.999,99.")]
    public decimal PrecoFinal { get; set; }

    public Ingresso ParaIngresso(int id = 0) => new()
    {
        IngressoID = id,
        JogoID = JogoID,
        SetorID = SetorID,
        AssentoID = AssentoID,
        PrecoFinal = PrecoFinal
    };

    public static IngressoSalvarDto De(Ingresso i) => new()
    {
        JogoID = i.JogoID,
        SetorID = i.SetorID,
        AssentoID = i.AssentoID ?? 0,
        PrecoFinal = i.PrecoFinal
    };
}
