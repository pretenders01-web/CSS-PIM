/// A resposta de POST /api/vendas/validar quando a entrada é liberada.
class IngressoValidado {
  const IngressoValidado({
    required this.ingressoId,
    required this.partida,
    required this.dataJogo,
    required this.nomeSetor,
    this.numeroAssento,
  });

  final int ingressoId;
  final String partida;
  final DateTime dataJogo;
  final String nomeSetor;
  final String? numeroAssento;

  factory IngressoValidado.fromJson(Map<String, dynamic> json) => IngressoValidado(
    ingressoId: json['ingressoId'] as int,
    partida: json['partida'] as String,
    dataJogo: DateTime.parse(json['dataJogo'] as String),
    nomeSetor: json['nomeSetor'] as String,
    numeroAssento: json['numeroAssento'] as String?,
  );
}
