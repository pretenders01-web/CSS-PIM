using System.Globalization;

namespace MundialTickets.Web.Servicos;

// Formatos de exibição em português do Brasil.
// A Web lê os formulários com a cultura invariante (número com ponto, como o <input type="number">
// envia), e só na HORA DE MOSTRAR usa o formato brasileiro, por estes métodos.
public static class Formatacao
{
    private static readonly CultureInfo Brasil = CultureInfo.GetCultureInfo("pt-BR");

    // R$ 1.200,00
    public static string Moeda(decimal valor) => valor.ToString("C", Brasil);

    // 11/06/2026
    public static string Data(DateTime data) => data.ToString("dd/MM/yyyy", Brasil);

    // 11/06/2026 às 16:00
    public static string DataHora(DateTime data) => data.ToString("dd/MM/yyyy 'às' HH:mm", Brasil);

    // 2026-06-11T16:00 (o formato que o <input type="datetime-local"> entende)
    public static string ParaCampoDataHora(DateTime data) => data.ToString("yyyy-MM-dd'T'HH:mm", CultureInfo.InvariantCulture);

    // 95.50 (com ponto, para o atributo value de um <input type="number">)
    public static string ParaCampoNumero(decimal valor) => valor.ToString("0.00", CultureInfo.InvariantCulture);
}
