/// Liga o NOME de um time ao arquivo da bandeira em assets/flags.
/// É a mesma tabela de Servicos/Bandeiras.cs da Web: o banco guarda só o nome do time.
const Map<String, String> _arquivos = {
  'argentina': 'argentina',
  'brasil': 'brazil',
  'canada': 'canada',
  'chile': 'chile',
  'dinamarca': 'denmark',
  'franca': 'france',
  'alemanha': 'germany',
  'japao': 'japan',
  'mexico': 'mexico',
  'servia': 'serbia',
  'uruguai': 'uruguay',
  'estados unidos': 'usa',
  'eua': 'usa',
};

const Map<String, String> _semAcento = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'é': 'e',
  'ê': 'e',
  'í': 'i',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ú': 'u',
  'ü': 'u',
  'ç': 'c',
};

/// Devolve o caminho do asset, ou null se o time não estiver na tabela.
String? arquivoDaBandeira(String? time) {
  if (time == null) return null;

  final chave = time
      .trim()
      .toLowerCase()
      .split('')
      .map((letra) => _semAcento[letra] ?? letra)
      .join();

  final arquivo = _arquivos[chave];
  return arquivo == null ? null : 'assets/flags/$arquivo.svg';
}
