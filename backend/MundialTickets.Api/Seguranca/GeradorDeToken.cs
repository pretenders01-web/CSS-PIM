using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using MundialTickets.Modelos;

namespace MundialTickets.Api.Seguranca;

// Cria o token JWT assinado com a chave que está no appsettings.json (seção "Jwt").
// O token leva quatro informações do usuário (as "claims"): o id, o nome, o e-mail e o
// perfil. É o perfil (CLIENTE ou ADMIN) que as rotas de administração conferem.
public class GeradorDeToken : IGeradorDeToken
{
    private readonly string _chave;
    private readonly string _emissor;
    private readonly string _audiencia;
    private readonly int _minutosDeValidade;

    public GeradorDeToken(IConfiguration configuracao)
    {
        var jwt = configuracao.GetSection("Jwt");
        _chave = jwt["Chave"] ?? throw new InvalidOperationException("Jwt:Chave não encontrada no appsettings.json.");
        _emissor = jwt["Emissor"] ?? throw new InvalidOperationException("Jwt:Emissor não encontrado no appsettings.json.");
        _audiencia = jwt["Audiencia"] ?? throw new InvalidOperationException("Jwt:Audiencia não encontrada no appsettings.json.");
        _minutosDeValidade = int.TryParse(jwt["ExpiraEmMinutos"], out var minutos) && minutos > 0 ? minutos : 120;

        // O algoritmo HMAC-SHA256 exige uma chave de pelo menos 256 bits (32 caracteres).
        if (Encoding.UTF8.GetByteCount(_chave) < 32)
            throw new InvalidOperationException("Jwt:Chave precisa ter pelo menos 32 caracteres.");
    }

    public (string Token, DateTime ExpiraEm) Gerar(Usuario usuario)
    {
        var expiraEm = DateTime.UtcNow.AddMinutes(_minutosDeValidade);

        var descricao = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.NameIdentifier, usuario.UsuarioID.ToString()),
                new Claim(ClaimTypes.Name, usuario.Nome),
                new Claim(ClaimTypes.Email, usuario.Email),
                new Claim(ClaimTypes.Role, usuario.Perfil)
            }),
            Issuer = _emissor,
            Audience = _audiencia,
            Expires = expiraEm,
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_chave)),
                SecurityAlgorithms.HmacSha256)
        };

        var token = new JsonWebTokenHandler().CreateToken(descricao);
        return (token, expiraEm);
    }
}
