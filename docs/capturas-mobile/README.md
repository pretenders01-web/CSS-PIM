# Capturas do app Mundial Tickets

Evidências da Etapa 9 do manual: "apresentação de telas, protótipos ou capturas do sistema". Foram feitas no emulador Android (1080×2424, Android 17), contra a Api e o banco locais, com contas temporárias, já apagadas. Os códigos de QR que aparecem não valem mais. O horário do histórico está em UTC, porque esse é o fuso do emulador.

| Arquivo | Tela |
|---|---|
| `00-fluxo-de-navegacao.png` | O fluxo de navegação do app (Etapa 6) |
| `01-login.png` | Login, com o aviso de que cadastro e compra ficam no site |
| `02-inicio.png` | Tela inicial: o cartão do próximo jogo, com o mapa, e os outros ingressos |
| `03-qr-valido.png` | QR Code com o selo Válido |
| `04-qr-utilizado.png` | O mesmo ingresso depois de validado: o selo mudou sozinho, com a tela aberta |
| `05-qr-expirado.png` | Selo Expirado, com o jogo no passado por uma alteração temporária no banco |
| `06-portaria-leitura.png` | Portaria, onde o `ADMIN` abre direto: contador, "Ler QR Code", campo de código e histórico vazio |
| `07-portaria-liberada.png` | Entrada liberada, em verde, com a contagem da volta automática |
| `08-portaria-recusada.png` | Entrada recusada, em vermelho, com o motivo |
| `09-estado-vazio.png` | Sem ingressos |
| `10-estado-erro.png` | Erro com "Tentar de novo", com a Api parada |
| `11-inicio-aparelho-pequeno.png` | Tela inicial em 360×640 dp |
| `12-inicio-aparelho-grande.png` | Tela inicial em 480×1040 dp |
| `13-inicio-fonte-grande.png` | Tela inicial com a fonte do sistema em 2,0 |
| `14-outros-ingressos.png` | A lista com os três selos |
| `15-portaria-camera.png` | A câmera, aberta por "Ler QR Code" (a cena virtual do emulador) |
| `16-portaria-historico.png` | O contador e o histórico da sessão, com entradas liberadas e recusadas |

A leitura de um QR real pela câmera ainda não tem captura: ela depende de um aparelho físico (passo 3.8 do plano).
