/// "16/12/2026 às 16:00", o mesmo formato de Servicos/Formatacao.cs da Web.
String formatarDataHora(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year} '
    'às ${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

/// "16:05:12", para o histórico da Portaria.
String formatarHora(DateTime data) =>
    '${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}:${_doisDigitos(data.second)}';

String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');
