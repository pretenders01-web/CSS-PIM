/// "16/12/2026 às 16:00", o mesmo formato de Servicos/Formatacao.cs da Web.
String formatarDataHora(DateTime data) {
  String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
      'às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}
