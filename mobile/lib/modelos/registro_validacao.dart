import 'ingresso_validado.dart';

enum ResultadoValidacao { liberada, recusada, naoValidada }

/// Uma validação feita nesta sessão da Portaria. Fica só em memória: nada vai para o aparelho.
class RegistroValidacao {
  const RegistroValidacao({
    required this.horario,
    required this.codigo,
    required this.resultado,
    this.partida,
    this.nomeSetor,
    this.numeroAssento,
    this.dataJogo,
    this.motivo,
  });

  final DateTime horario;
  final String codigo;
  final ResultadoValidacao resultado;

  /// Na recusa, a Api devolve só o motivo. Estes campos ficam nulos, a menos que o mesmo código
  /// já tenha sido liberado nesta sessão.
  final String? partida;
  final String? nomeSetor;
  final String? numeroAssento;
  final DateTime? dataJogo;

  /// O motivo da recusa ou da falha.
  final String? motivo;

  factory RegistroValidacao.liberada(String codigo, DateTime horario, IngressoValidado validado) => RegistroValidacao(
    horario: horario,
    codigo: codigo,
    resultado: ResultadoValidacao.liberada,
    partida: validado.partida,
    nomeSetor: validado.nomeSetor,
    numeroAssento: validado.numeroAssento,
    dataJogo: validado.dataJogo,
  );
}
