using System.Security.Cryptography;

namespace MundialTickets.Negocio;

// Hash de senha com PBKDF2 (Rfc2898DeriveBytes.Pbkdf2, que já faz parte do .NET).
// Cada senha ganha um sal aleatório próprio, então duas senhas iguais geram hashes diferentes.
// O texto guardado é "iterações.sal.hash" (sal e hash em Base64), com cerca de 80 caracteres,
// e cabe folgado nos 255 da coluna Usuario.SenhaHash. Guardar as iterações junto permite
// aumentar o número no futuro sem invalidar as senhas já gravadas.
public class HashDeSenha : IHashDeSenha
{
    private const int TamanhoDoSal = 16;
    private const int TamanhoDoHash = 32;
    private const int Iteracoes = 100_000;

    public string Gerar(string senha)
    {
        var sal = RandomNumberGenerator.GetBytes(TamanhoDoSal);
        var hash = Rfc2898DeriveBytes.Pbkdf2(senha, sal, Iteracoes, HashAlgorithmName.SHA256, TamanhoDoHash);
        return $"{Iteracoes}.{Convert.ToBase64String(sal)}.{Convert.ToBase64String(hash)}";
    }

    public bool Verificar(string senha, string hashGuardado)
    {
        var partes = hashGuardado.Split('.');
        if (partes.Length != 3 || !int.TryParse(partes[0], out var iteracoes) || iteracoes <= 0)
            return false;

        try
        {
            var sal = Convert.FromBase64String(partes[1]);
            var esperado = Convert.FromBase64String(partes[2]);
            var calculado = Rfc2898DeriveBytes.Pbkdf2(senha, sal, iteracoes, HashAlgorithmName.SHA256, esperado.Length);

            // Comparação em tempo constante: não revela, pelo tempo de resposta, quantos bytes batem.
            return CryptographicOperations.FixedTimeEquals(calculado, esperado);
        }
        catch (FormatException)
        {
            return false;   // texto guardado fora do formato esperado
        }
    }
}
