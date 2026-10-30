namespace MundialTickets.Negocio;

// Lançada quando uma regra de negócio é violada (e-mail repetido, CPF inválido...).
// Os controllers capturam esta exceção e mostram a mensagem para o usuário:
// na Web, como erro no formulário; na Api, como 400 Bad Request.
public class RegraDeNegocioException : Exception
{
    public RegraDeNegocioException(string mensagem) : base(mensagem) { }
}
