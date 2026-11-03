using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA do login da Api (POST /api/auth/login).
// O app guarda o Token e o envia em todas as chamadas que exigem login, no cabeçalho
// "Authorization: Bearer <token>".
public class LoginRespostaDto
{
    [Display(Name = "Token")]
    public string Token { get; set; } = string.Empty;

    // Data e hora (UTC) em que o token deixa de valer; depois disso o app pede o login de novo.
    [Display(Name = "Válido até")]
    public DateTime ExpiraEm { get; set; }

    public UsuarioDto Usuario { get; set; } = new();
}
