namespace MundialTickets.Modelos.Constantes;

// Valores aceitos pela coluna Usuario.Perfil (restrição CHECK do banco).
// O cadastro cria sempre CLIENTE; ADMIN só é dado por quem tem acesso ao banco.
public static class PerfilUsuario
{
    public const string Cliente = "CLIENTE";
    public const string Admin = "ADMIN";
}
