using MundialTickets.Modelos;

namespace MundialTickets.Api.Seguranca;

// Contrato do serviço que cria o token JWT de um usuário que acabou de fazer login.
// Fica na Api (e não no Negócio) porque o JWT é um detalhe da porta de entrada do app:
// a Web usa cookie e não precisa dele.
public interface IGeradorDeToken
{
    // Devolve o token e a data e hora (UTC) em que ele deixa de valer.
    (string Token, DateTime ExpiraEm) Gerar(Usuario usuario);
}
