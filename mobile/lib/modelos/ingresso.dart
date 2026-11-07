/// Um ingresso comprado, como vem em GET /api/vendas/meus-ingressos.
class Ingresso {
  const Ingresso({
    required this.ingressoId,
    required this.vendaId,
    required this.partida,
    required this.timeA,
    required this.timeB,
    required this.dataJogo,
    required this.estadioNome,
    required this.estadioCidade,
    required this.nomeSetor,
    required this.precoPago,
    required this.codigoQR,
    required this.utilizado,
    this.numeroAssento,
  });

  final int ingressoId;
  final int vendaId;
  final String partida;
  final String timeA;
  final String timeB;

  /// A data atual do jogo. Vem sem fuso e é lida como hora local, com os mesmos dígitos do site.
  final DateTime dataJogo;
  final String estadioNome;
  final String estadioCidade;
  final String nomeSetor;

  /// O banco aceita ingresso sem assento.
  final String? numeroAssento;
  final double precoPago;

  /// Atenção à grafia do JSON: "codigoQR", com "QR" maiúsculo.
  final String codigoQR;
  final bool utilizado;

  factory Ingresso.fromJson(Map<String, dynamic> json) => Ingresso(
    ingressoId: json['ingressoId'] as int,
    vendaId: json['vendaId'] as int,
    partida: json['partida'] as String,
    timeA: json['timeA'] as String,
    timeB: json['timeB'] as String,
    dataJogo: DateTime.parse(json['dataJogo'] as String),
    estadioNome: json['estadioNome'] as String,
    estadioCidade: json['estadioCidade'] as String,
    nomeSetor: json['nomeSetor'] as String,
    numeroAssento: json['numeroAssento'] as String?,
    // O JSON traz 450 ou 450.00, conforme o valor. "num" aceita os dois.
    precoPago: (json['precoPago'] as num).toDouble(),
    codigoQR: json['codigoQR'] as String,
    utilizado: json['utilizado'] as bool,
  );
}
