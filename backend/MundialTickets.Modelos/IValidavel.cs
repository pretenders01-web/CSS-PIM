namespace MundialTickets.Modelos;

// Contrato para classes que sabem dizer se os próprios dados estão corretos.
public interface IValidavel
{
    // Devolve true se os dados forem válidos e false se existir alguma informação incorreta.
    bool Validar();
}
