using MundialTickets.Modelos;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Negocio;

// Regras do usuário: cadastro, login, alteração dos próprios dados e desativação da conta.
// Web e Api chamam esta classe; esta classe chama o repositório.
public class UsuarioNegocio
{
    private readonly IUsuarioRepositorio _repositorio;
    private readonly IHashDeSenha _hash;

    // INJEÇÃO DE DEPENDÊNCIA: o repositório e o serviço de hash chegam prontos no construtor.
    public UsuarioNegocio(IUsuarioRepositorio repositorio, IHashDeSenha hash)
    {
        _repositorio = repositorio;
        _hash = hash;
    }

    // Cria uma conta de comprador. O perfil é SEMPRE CLIENTE: mesmo que a tela ou a requisição
    // tentasse mandar ADMIN, o valor é ignorado aqui.
    public Usuario Cadastrar(Usuario usuario, string senha, string confirmarSenha)
    {
        if (string.IsNullOrWhiteSpace(senha))
            throw new RegraDeNegocioException("Informe a senha.");
        if (senha != confirmarSenha)
            throw new RegraDeNegocioException("As senhas não conferem.");

        Normalizar(usuario);
        ValidarDados(usuario, ignorarId: null);

        usuario.Perfil = PerfilUsuario.Cliente;
        usuario.Ativo = true;
        usuario.SenhaHash = _hash.Gerar(senha);

        _repositorio.Adicionar(usuario);
        return usuario;
    }

    // Confere e-mail e senha. A mensagem é a mesma para e-mail desconhecido e senha errada,
    // para não revelar a ninguém quais e-mails têm conta. O aviso de conta desativada só
    // aparece depois que a senha está certa.
    public Usuario Autenticar(string email, string senha)
    {
        var usuario = _repositorio.ObterPorEmail((email ?? string.Empty).Trim().ToLowerInvariant());

        if (usuario is null || string.IsNullOrEmpty(senha) || !_hash.Verificar(senha, usuario.SenhaHash))
            throw new RegraDeNegocioException("E-mail ou senha incorretos.");

        if (!usuario.Ativo)
            throw new RegraDeNegocioException("Esta conta está desativada.");

        return usuario;
    }

    public Usuario? ObterPorId(int id) => _repositorio.ObterPorId(id);

    // Altera os dados do próprio usuário. A senha só muda se uma nova senha for informada.
    public Usuario Atualizar(int usuarioId, string nome, string email, string? cpf, string? novaSenha, string? confirmarNovaSenha)
    {
        var usuario = _repositorio.ObterPorId(usuarioId)
            ?? throw new RegraDeNegocioException("Usuário não encontrado.");

        if (!usuario.Ativo)
            throw new RegraDeNegocioException("Esta conta está desativada.");

        var dados = new Usuario { Nome = nome, Email = email, CPF = cpf };
        Normalizar(dados);
        ValidarDados(dados, ignorarId: usuarioId);

        if (!string.IsNullOrWhiteSpace(novaSenha))
        {
            if (novaSenha != confirmarNovaSenha)
                throw new RegraDeNegocioException("As senhas não conferem.");
            usuario.SenhaHash = _hash.Gerar(novaSenha);
        }

        usuario.Nome = dados.Nome;
        usuario.Email = dados.Email;
        usuario.CPF = dados.CPF;

        _repositorio.Atualizar(usuario);
        return usuario;
    }

    // "Excluir conta" desativa o usuário (Ativo = 0). O banco recusa apagar quem já comprou.
    public void Desativar(int usuarioId)
    {
        if (!_repositorio.Desativar(usuarioId))
            throw new RegraDeNegocioException("Usuário não encontrado.");
    }

    // ---------- regras ----------

    private static void Normalizar(Usuario usuario)
    {
        usuario.Nome = (usuario.Nome ?? string.Empty).Trim();
        usuario.Email = (usuario.Email ?? string.Empty).Trim().ToLowerInvariant();

        // O CPF é opcional. Quando vem, guarda só os dígitos: "123.456.789-09" vira "12345678909".
        usuario.CPF = string.IsNullOrWhiteSpace(usuario.CPF)
            ? null
            : new string(usuario.CPF.Where(char.IsDigit).ToArray());
    }

    private void ValidarDados(Usuario usuario, int? ignorarId)
    {
        if (!usuario.Validar())
            throw new RegraDeNegocioException("Informe o nome e um e-mail válido.");

        if (usuario.CPF is not null && usuario.CPF.Length != 11)
            throw new RegraDeNegocioException("O CPF precisa ter 11 dígitos.");

        if (_repositorio.EmailEmUso(usuario.Email, ignorarId))
            throw new RegraDeNegocioException("Já existe uma conta com este e-mail.");
    }
}
