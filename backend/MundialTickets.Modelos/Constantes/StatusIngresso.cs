namespace MundialTickets.Modelos.Constantes;

// Valores aceitos pela coluna Ingresso.Status (o banco tem uma restrição CHECK com
// estes quatro). Usar as constantes evita texto solto e erro de digitação no código.
public static class StatusIngresso
{
    public const string Disponivel = "DISPONIVEL";
    public const string Reservado = "RESERVADO";
    public const string Vendido = "VENDIDO";
    public const string Cancelado = "CANCELADO";
}
