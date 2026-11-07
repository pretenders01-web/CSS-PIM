using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA da validação na portaria (POST /api/vendas/validar): o texto lido no QR.
public class IngressoValidarDto
{
    [Display(Name = "Código do QR")]
    [Required(ErrorMessage = "Informe o código do QR.")]
    [StringLength(255, ErrorMessage = "O código do QR pode ter no máximo 255 caracteres.")]
    public string CodigoQR { get; set; } = string.Empty;
}
