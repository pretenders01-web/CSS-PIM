namespace MundialTickets.Negocio;

// Contrato do serviço que transforma a senha em hash e confere uma senha digitada.
// O UsuarioNegocio depende deste contrato, não da classe concreta.
public interface IHashDeSenha
{
    // Gera o texto que vai para a coluna Usuario.SenhaHash. A senha em si nunca é gravada.
    string Gerar(string senha);

    // Confere uma senha digitada contra o texto guardado no banco.
    bool Verificar(string senha, string hashGuardado);
}
