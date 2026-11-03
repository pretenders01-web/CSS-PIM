using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA da criação de assentos em lote (POST /api/assentos/lote e a segunda
// seção da página de Assento): o administrador diz o setor e a quantidade, e o sistema
// cria os números (A01, A02...).
public class AssentoLoteDto
{
    [Display(Name = "Setor")]
    [Range(1, int.MaxValue, ErrorMessage = "Escolha o setor.")]
    public int SetorID { get; set; }

    [Display(Name = "Quantidade")]
    [Range(1, 1000, ErrorMessage = "A quantidade deve estar entre 1 e 1000.")]
    public int Quantidade { get; set; }

    // Opcional: em branco, o Negócio usa "A".
    [Display(Name = "Prefixo")]
    [StringLength(10, ErrorMessage = "O prefixo pode ter no máximo 10 caracteres.")]
    public string? Prefixo { get; set; }
}
