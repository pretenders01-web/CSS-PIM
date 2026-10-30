using MundialTickets.Modelos;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Negocio;

// Aqui moram as regras de negócio do cliente.
// Web e Api chamam esta classe; esta classe chama o repositório.
// Nenhuma regra fica no controller nem na view.
public class ClienteNegocio
{
    private readonly IClienteRepositorio _repositorio;

    // INJEÇÃO DE DEPENDÊNCIA: esta classe precisa de um repositório para trabalhar,
    // mas não cria um com "new". Ela PEDE no construtor, e o ASP.NET Core entrega.
    // Quem diz ao ASP.NET qual classe entregar quando alguém pede IClienteRepositorio
    // é a linha AddScoped<IClienteRepositorio, ClienteRepositorio>() do Program.cs.
    // Explicação completa: INJECAO-DE-DEPENDENCIA.md, na pasta da solution.
    public ClienteNegocio(IClienteRepositorio repositorio)
    {
        _repositorio = repositorio;
    }

    public List<Cliente> Listar() => _repositorio.Listar();

    public Cliente? ObterPorId(int id) => _repositorio.ObterPorId(id);

    public List<Cliente> BuscarPorNome(string trecho) =>
        _repositorio.BuscarPorNome(trecho?.Trim() ?? string.Empty);

    public Cliente Cadastrar(Cliente cliente)
    {
        Normalizar(cliente);
        Validar(cliente, ignorarId: null);

        cliente.Ativo = true;
        _repositorio.Adicionar(cliente);
        return cliente;
    }

    public void Atualizar(Cliente cliente)
    {
        var existente = _repositorio.ObterPorId(cliente.Id)
            ?? throw new RegraDeNegocioException("Cliente não encontrado.");

        Normalizar(cliente);
        Validar(cliente, ignorarId: cliente.Id);

        // Copia só o que pode mudar; DataCadastro continua a original.
        existente.Nome = cliente.Nome;
        existente.Email = cliente.Email;
        existente.Cpf = cliente.Cpf;
        existente.Ativo = cliente.Ativo;

        _repositorio.Atualizar(existente);
    }

    // Devolve false quando o cliente não existe.
    public bool Remover(int id)
    {
        var cliente = _repositorio.ObterPorId(id);
        if (cliente is null) return false;

        _repositorio.Remover(cliente);
        return true;
    }

    // ---------- regras ----------

    private static void Normalizar(Cliente cliente)
    {
        cliente.Nome = cliente.Nome.Trim();
        cliente.Email = cliente.Email.Trim().ToLowerInvariant();
        // Guarda só os dígitos: "123.456.789-09" vira "12345678909".
        cliente.Cpf = new string(cliente.Cpf.Where(char.IsDigit).ToArray());
    }

    private void Validar(Cliente cliente, int? ignorarId)
    {
        if (cliente.Cpf.Length != 11)
            throw new RegraDeNegocioException("O CPF precisa ter 11 dígitos.");

        if (_repositorio.EmailEmUso(cliente.Email, ignorarId))
            throw new RegraDeNegocioException("Já existe um cliente com este e-mail.");

        if (_repositorio.CpfEmUso(cliente.Cpf, ignorarId))
            throw new RegraDeNegocioException("Já existe um cliente com este CPF.");
    }
}
