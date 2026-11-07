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
| `20-paisagem-login.png` | Deitado: login centralizado, com logo e título na mesma linha |
| `21-paisagem-inicio.png` | Deitado: o cartão com os dados de um lado, e o mapa e os botões do outro |
| `22-paisagem-outros-ingressos.png` | Deitado: os outros ingressos em duas colunas, depois de rolar a lista |
| `23-paisagem-qr-valido.png` | Deitado: o QR à esquerda e os dados à direita |
| `24-paisagem-qr-utilizado.png` | Deitado: o mesmo ingresso depois de validado, com o selo que mudou sozinho |
| `25-paisagem-portaria.png` | Deitado: a leitura à esquerda, e o contador e o histórico à direita |
| `26-paisagem-portaria-liberada.png` | Deitado: entrada liberada, com o ícone ao lado dos textos |
| `27-paisagem-portaria-recusada.png` | Deitado: entrada recusada, com o motivo |
| `28-paisagem-portaria-historico.png` | Deitado: o histórico rolado, com o contador e o campo sempre à vista |
| `29-paisagem-camera.png` | Deitado: a câmera, com a cena virtual do emulador em pé e o aparelho simulado girado |
| `30-paisagem-estado-vazio.png` | Deitado: sem ingressos |
| `31-paisagem-estado-erro.png` | Deitado: erro com "Tentar de novo", com a Api parada |

A leitura de um QR real pela câmera ainda não tem captura, nem em pé nem deitado: ela depende de um aparelho físico (passo 3.8 do plano).
