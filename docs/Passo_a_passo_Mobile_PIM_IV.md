# Passo a passo: app Flutter do PIM IV (Mundial Tickets)

Plano para construir o aplicativo que o manual pede: "deve ser desenvolvido em Flutter um aplicativo que consuma a Web API e implemente ao menos uma funcionalidade complementar ao sistema". A Etapa 9 detalha a parte mobile. A funcionalidade complementar é **mostrar o ingresso e validá-lo na portaria**.

Este documento descreve o que fazer e registra o que já foi decidido. O que ele afirma sobre a Api, os DTOs, os scripts do banco e a pasta `mobile/` foi conferido nos arquivos em 07/11/2026. Os testes feitos nessa conferência estão na seção 1, com o que **não** pôde ser testado. As dúvidas de produto foram respondidas e estão na seção 4.

Fora do escopo: cadastro e compra no app (ficam no site), mapa real, funcionamento sem rede, publicação em loja e testes em iOS (exigem um Mac, e esta máquina é Windows).

---

## Resumo das fases

Marque cada fase aqui quando todos os passos dela (seção 5) estiverem concluídos.

- [x] **Fase 1:** backend (dados do cartão, validação do ingresso, datas futuras e contas de teste)
- [ ] **Fase 2:** app completo, executado em sequência, sem parar entre as partes, com um commit por parte
  - [ ] **Parte 2A:** base do app (pacotes, tema, assets e configuração)
  - [ ] **Parte 2B:** camada de dados e login
  - [ ] **Parte 2C:** tela inicial com o cartão e o mapa
  - [ ] **Parte 2D:** tela do QR Code
  - [ ] **Parte 2E:** modo Portaria
- [ ] **Fase 3:** acabamento (responsividade, acessibilidade, testes, capturas e README)

---

## 1. Situação atual (verificada)

Retrato de 07/11/2026, antes da Fase 1. O que a Fase 1 mudar fica nas notas dela.

| Item | Estado |
|---|---|
| `mobile/` | Código padrão do `flutter create`: `lib/main.dart` e `test/widget_test.dart` (contador). Pacotes: só `cupertino_icons` e `flutter_lints`. Não há pasta `assets` |
| Flutter nesta máquina | 3.47.9 com Dart 3.13.7, o que atende ao `sdk: ^3.13.7` do `pubspec.yaml` |
| Versões do Android | `minSdk` 24, `targetSdk` e `compileSdk` 36, herdados de `flutter.*` no `build.gradle.kts`. Atendem aos pacotes escolhidos (os mais exigentes pedem 24) |
| Manifesto principal do Android | **Sem permissão de internet** (ela só existe nos manifestos de `debug` e `profile`), `android:label="mobile"`, sem `allowBackup` e sem `usesCleartextTraffic`. O `<queries>` só cobre `PROCESS_TEXT` |
| iOS | `Info.plist` sem `NSCameraUsageDescription` |
| Build Android | Nunca tinha sido feito (`mobile/build` não tem saída Android). O build de teste abaixo só passou depois de repetido e baixou no SDK o NDK 28.2.13676358 (2,2 GB), o CMake 3.22.1 e as plataformas 35 e 36. A primeira tentativa falhou com "sdkmanager did not install NDK". Cada máquina do grupo fará esse download no primeiro build |
| Emulador | `sdk gphone64 x86 64` (`emulator-5554`, Android 17, API 37) **é o aparelho principal** (decisão 4.9). Só passou a iniciar depois de o dono da máquina ligar a virtualização (SVM) e a Plataforma do Hipervisor do Windows. O app padrão foi compilado e rodou nele |
| Edge e Android de um colega | O `flutter devices` lista o Edge, que é o plano B. O Android de um colega fica para as capturas, a apresentação e a leitura pela câmera (passo 3.8) |
| Banco `CopaDoMundoVendas` | 7 estádios, 21 setores, 175 assentos, 6 jogos, 150 ingressos e **0 usuários, 0 vendas e 0 QR codes**. Os 6 jogos eram de 11 a 18/06/2026, todos no passado |
| Api | Sobe no .NET 10 pelo `RollForward` (a máquina tem os SDKs 8 e 10). Tem 21 caminhos no OpenAPI, nenhum para renovar o token nem para consultar um único ingresso do comprador |
| Manual | Sem data de entrega no documento (ele fala em "datas publicadas") |

**Testes feitos nesta conferência** (fora do repositório, sem nada gravado no banco):

| Teste | Resultado |
|---|---|
| Api com `--launch-profile http -- --urls http://0.0.0.0:5218` | Escutou em `0.0.0.0:5218`. `GET /api/jogos` respondeu 200 por `localhost` e pelo IP da rede local, chamado do próprio PC. Em log, só o aviso `Failed to determine the https port for redirect`, sem redirecionar |
| CORS | A pré-verificação com `authorization` e `content-type` respondeu 204 e `Access-Control-Allow-Origin: *` |
| Erros da Api | Ver a seção 3.2 (login errado, login inválido e chamada sem token) |
| Os 6 pacotes em um projeto temporário | Resolvem no Dart 3.13.7, e o `flutter build apk --debug` passa |
| Manifesto final desse build | O `mobile_scanner` já acrescenta `CAMERA` e `uses-feature camera required=false` |
| As 12 bandeiras com `flutter_svg` | 9 corretas. **México, Sérvia e Uruguai saem com as cores erradas** (seção 3.6), e a conversão do passo 2A.3 corrigiu as três |
| `qr_flutter` com um código de 40 caracteres | Válido, versão 3, 29 módulos |
| `flutter_launcher_icons` como `dev_dependency` | Resolve na versão 0.14.4 |
| App com `usesCleartextTraffic="false"` chamando a Api por HTTP, no emulador | Respondeu 200 por `10.0.2.2` e por `localhost` com `adb reverse`. **Confirma que o manifesto não bloqueia o HTTP do Dart** (passo 2A.6) |

**Não testado** (o passo indicado confere): bloqueio de HTTP em build de release (passo 2A.6); leitura pela câmera e acesso a partir de um celular de verdade, com o firewall do Windows (passo 3.8). Hero, mapa, consulta periódica e telas não foram prototipados.

---

## 2. Escopo e decisões já tomadas

As respostas às dúvidas de produto estão na seção 4.

| Tema | Decisão |
|---|---|
| Nível do trabalho | O de um trabalho acadêmico de ADS: nem avançado demais, nem básico demais. **Fora:** BLoC, Riverpod com geração de código, pacotes de injeção de dependência e geradores de código |
| Camadas | Simples: modelos, serviços, telas e widgets |
| Estado e navegação | `setState` nas telas e um `ChangeNotifier` só para a sessão, na forma de `ValueNotifier` (já vem no Flutter). O pacote `provider` só entra se passar a sessão por construtor ficar incômodo. Navegação com `Navigator.push`. Os serviços são passados por construtor, o que também permite usar versões falsas nos testes |
| Login | Com a conta criada no site, por `POST /api/auth/login`. Sem cadastro e sem compra no app, e a tela de login avisa isso |
| Tela inicial | Um cartão com cerca de metade da tela mostra o próximo jogo: o ingresso não utilizado com a data mais próxima ainda no futuro. Traz bandeiras e nomes dos times, setor, assento, data e hora, estádio e cidade. Abaixo, a lista dos outros ingressos |
| Mapa | Ilustrado e animado, com `CustomPainter` e `AnimationController`: uma rota se desenha até uma bandeira. Sem mapa real e sem chave de API. O botão "Como chegar" abre o Google Maps com o estádio e a cidade |
| Validar ingresso | O botão expande o cartão com Hero até a tela do QR Code, desenhado a partir do `CodigoQR`, com o selo Válido, Utilizado ou Expirado |
| Consulta periódica | Só com a tela do QR aberta, a cada poucos segundos, para o selo mudar quando a portaria validar |
| Modo Portaria | Só para `ADMIN`. Lê o QR pela câmera ou recebe o código digitado ou colado, e chama a Api. Resposta grande em verde (entrada liberada, com partida, setor e assento) ou vermelho (com o motivo) |
| Backend | Fase própria, com commit separado, antes do app. `backend/` e `5.database/` só mudam para o que a Fase 1 descreve |
| Contas de teste | Um comprador com 3 ingressos e um `ADMIN`, criados pela Api só no banco local. **Nada de e-mail ou senha entra no repositório** |
| Ordem das fases | Fase 1 primeiro. A Fase 2 roda de uma vez, com um commit por parte, e a Fase 3 fecha |
| Visual | Igual ao site (seção 3.5), com logo e bandeiras copiados para `mobile/assets` e Poppins empacotada, sem download em tempo de execução. O logo também é o ícone do app |
| Segurança | Token em armazenamento seguro; senha nunca guardada nem em log; expiração respeitada; 401 volta ao login; endereço da Api por `--dart-define`; internet no manifesto principal; HTTP sem criptografia só em debug; câmera só na Portaria |

### Pacotes

Versões que resolveram no teste da seção 1.

| Pacote | Versão | Para quê | Por que este |
|---|---|---|---|
| `http` | 1.6.0 | Chamar a Api | Mantido pelo time do Dart, simples, funciona no Android e no Edge sem `dart:io`, e traz o `MockClient` para os testes |
| `flutter_secure_storage` | 11.2.0 | Guardar a sessão | Cifra no Android (RSA OAEP e AES-GCM, segundo o README). É o que cumpre "nunca em SharedPreferences" |
| `flutter_svg` | 2.3.2 | Desenhar as bandeiras | O Flutter não desenha `.svg` sozinho, e assim o app usa as bandeiras do site |
| `qr_flutter` | 4.1.0 | Desenhar o QR | O mais simples para gerar a imagem a partir do texto. A última versão é de 2023, e funcionou no teste (seção 7) |
| `mobile_scanner` | 7.5.0 | Ler o QR pela câmera | Suporta Android, iOS e Web, e pede a permissão sozinho ao abrir a câmera |
| `url_launcher` | 6.3.3 | Abrir o Google Maps | Solução padrão para abrir um link fora do app, sem chave de API |
| `flutter_localizations` | SDK | Rótulos do Material em pt-BR | Faz o leitor de tela dizer "Voltar", e não "Back". Já vem com o Flutter |
| `flutter_launcher_icons` | 0.14.4, só em `dev_dependencies` | Gerar o ícone do app a partir do logo | Roda uma vez e gera imagens. Não entra no app |

Sai o `cupertino_icons`, porque o app só usa ícones Material. **Não entram:** `google_fonts` (baixa a fonte em tempo de execução), `shared_preferences` (proibido para o token), `permission_handler` (o `mobile_scanner` já pede), `intl` direto (a data é formatada à mão, como em `Servicos/Formatacao.cs`), `visibility_detector` (o passo 2C.6 explica por que não é preciso), `flutter_bloc`, `get_it`, `build_runner` e `json_serializable` (critério de nível acima).

### Organização em camadas

```
mobile/lib/
  main.dart, app.dart   início do app, tema e decisão entre login e tela inicial
  config/               endereço da Api vindo do --dart-define
  tema/                 cores e ThemeData
  modelos/              Usuario, Sessao, Ingresso, IngressoValidado (cada um com fromJson)
  servicos/             ClienteApi, AutenticacaoServico, IngressoServico, ArmazenamentoSessao, erros
  telas/                login, início, QR e Portaria
  widgets/              cartão de vidro, selo, bandeira, cartão do jogo, mapa, carregando/vazio/erro
  util/                 bandeiras, formatação de data, validação de campos
mobile/test/            a mesma divisão: modelos, servicos, telas, util
```

As telas só falam com os serviços, e só o `ClienteApi` faz HTTP. É a mesma ideia do "controller só fala com o Negócio" do backend, e o app nunca fala com o banco.

---

## 3. O que a Api, os DTOs e o banco já definem

Convenção: **[API]** ou **[BANCO]** = já existe e o app respeita; **[PROPOSTA]** = escolha deste plano.

### 3.1 Contrato usado pelo app (nomes do JSON conferidos em `/openapi/v1.json`)

| Rota | Acesso | Envia | Devolve |
|---|---|---|---|
| `POST /api/auth/login` | público | `email`, `senha` | `token`, `expiraEm`, `usuario` (`id`, `nome`, `email`, `cpf`, `dataCadastro`, `ativo`, `perfil`) |
| `GET /api/usuarios/me` | logado | | Os mesmos campos de `usuario`. **401 se a conta foi desativada** |
| `GET /api/vendas/meus-ingressos` | logado | | Lista de `ingressoId`, `vendaId`, `partida`, `timeA`, `timeB`, `dataJogo`, `estadioNome`, `estadioCidade`, `nomeSetor`, `numeroAssento` (pode ser nulo), `precoPago`, `codigoQR`, `dataExpiracao`, `utilizado`. Os campos dos times e do estádio vieram na Fase 1 |
| `POST /api/vendas/validar` | `ADMIN` | `codigoQR` | `ingressoId`, `partida`, `dataJogo`, `nomeSetor`, `numeroAssento` (pode ser nulo). Recusa: 400 com `erro`. Criada na Fase 1 |

Atenção à grafia: é `codigoQR`, com "QR" maiúsculo. A lista vem ordenada por `Jogo.DataHora`, sem filtro de data nem de situação. O token vale 120 minutos (`ExpiraEmMinutos`) e não pode ser renovado: ao vencer, o usuário entra de novo. O perfil do usuário vai **dentro do token**, então quem é promovido a `ADMIN` só passa a ter acesso depois de um novo login, mesmo com `/me` já dizendo `ADMIN`.

### 3.2 Como os erros chegam

| Situação | Código | Corpo | O que o app faz |
|---|---|---|---|
| E-mail ou senha errados (testado) | 401 | `{"erro":"E-mail ou senha incorretos."}` | Mostra a mensagem no formulário. **Não** é sessão vencida |
| Conta desativada no login | 401 | `{"erro":"Esta conta está desativada."}` | Igual à linha acima |
| Campo inválido no DTO (testado) | 400 | `application/problem+json` com `errors`, por exemplo `{"Email":["E-mail inválido."]}`. **Não tem `erro`** | Mostra a primeira mensagem de `errors` |
| Regra de negócio | 400 | `{"erro":"..."}`, pelo `RegraDeNegocioFiltro` | Mostra `erro` |
| Sem token, token vencido ou inválido (sem token: testado) | 401 | **Vazio**, com `WWW-Authenticate: Bearer` | Limpa a sessão e volta ao login |
| Perfil sem permissão | 403 | Vazio (testado na Fase 5 do plano do C#) | Avisa e sugere entrar de novo |
| Erro inesperado | 500 | Pode nem ser JSON | Mensagem genérica, sem detalhe técnico |

Por isso o tratamento procura `erro`, depois `errors`, e por fim usa um texto padrão, sem nunca supor que o corpo é JSON válido.

### 3.3 Datas

- `dataJogo` vem sem fuso (testado em `GET /api/jogos`, com a mesma coluna: `"dataHora":"2026-06-11T16:00:00"`). O Dart lê como hora local, e o app mostra os mesmos dígitos do site, no formato `dd/MM/yyyy às HH:mm` de `Servicos/Formatacao.cs`.
- `expiraEm` vem em UTC, com `Z` e 7 casas decimais (testado: `2026-11-07T06:00:49.8521744Z`). O `DateTime.parse` do Dart aceita esse formato (testado).
- A Api aceita 1 minuto de diferença de relógio (`ClockSkew`).

### 3.4 QR code e dados de teste **[BANCO]**

- A trigger `trg_ItemVenda_GerarQRCode` cria o código como `NEWID()` + `-` + `IngressoID`, e copia `Jogo.DataHora` para `DataExpiracao` **no momento da venda**. `JogoNegocio.Atualizar` muda `Jogo.DataHora` sem tocar nessa cópia, então ela pode ficar velha. Por isso a validação e o app decidem por `Jogo.DataHora`, e **`DataExpiracao` não decide nada** (decisão 4.4). A coluna e o campo do DTO continuam existindo.
- `QRCode.Utilizado` é `bit NULL` com padrão 0, e a trigger sempre grava 0. `CodigoQR` e `IngressoID` são únicos. A tabela `QRCode` não tem trigger, e não há coluna com a hora da validação.
- `Ingresso.Status` só sai de `VENDIDO` por SQL direto: o `IngressoNegocio` recusa cancelar ou excluir um ingresso vendido. A conferência do status é uma proteção a mais.
- **Repetir o `05_Dados_Teste.sql` com datas novas não muda nada:** o `INSERT` de `Jogo` só roda quando não existe jogo com o mesmo estádio e os mesmos times. O passo 1.8 precisa de um `UPDATE` de `Jogo.DataHora`.
- A regra "`QRCode` é gravado só pela procedure e pelas triggers, nunca pelo EF" (plano do C# e comentário do `VendaRepositorio`) **deixa de valer** para o campo `Utilizado`. O passo 1.9 registra a exceção.

### 3.5 Visual (fonte: `wwwroot/css/mundial.css`)

| Elemento | Valores |
|---|---|
| Cores | Fundo `#0d0d0d`, verde `#277234`, verde forte `#329643` (o hover do site), amarelo `#FFCC29`, vermelho `#ff4d4d`, texto suave branco a 70% |
| `.cartao-vidro` | Fundo branco a 5%, borda branca a 8%, raio 18, sombra preta a 40%. O site usa `backdrop-filter: blur(10px)`. **No app não entra**: sobre fundo liso o desfoque não muda a imagem e custa caro em um cartão animado |
| `.btn-mt` | Fundo verde, texto branco em maiúsculas, peso 700, raio 12 |
| `.selo` | Pílula de raio 20, peso 700, em maiúsculas. Válido: `.selo-verde` (verde a 30%, borda verde). Utilizado: `.selo-cinza` (branco a 8%, texto suave). Expirado, só no app: `.selo-vermelho` (vermelho a 15%, borda vermelha a 50%, texto `#ff9a9a`). A Web continua com dois selos, escolhidos só por `Utilizado` (`Views/MeusIngressos/Index.cshtml:32`) |
| Poppins | O site carrega do Google Fonts e usa os pesos 400 a 900. O app empacota 400, 500, 600, 700 e 800: o 900 só aparece em duas regras do site, e o cartão não precisa dele |

Contraste calculado pela fórmula da WCAG (mínimo AA: 4,5 para texto comum e 3 para texto grande):

| Combinação | Contraste | Uso |
|---|---|---|
| Branco sobre `#277234` | 5,93 | Botões e tela verde da Portaria |
| `#329643` sobre `#0d0d0d` | 5,16 | Texto verde sobre o fundo |
| `#277234` sobre `#0d0d0d` | 3,28 | **Só em texto grande e ícones** |
| **Branco sobre `#ff4d4d`** | **3,27** | **Reprova em texto comum.** A tela vermelha da Portaria usa `#0d0d0d` (5,94) |
| Amarelo sobre `#0d0d0d` | 12,88 | Destaques |
| Texto suave sobre cartão de vidro | 9,06 | Rótulos do cartão |
| Selo Válido, Utilizado e Expirado | 13,42, 7,70 e 7,22 | Selos |

### 3.6 Bandeiras e logo

- `Servicos/Bandeiras.cs` tem 13 chaves (nome sem acento e em minúsculas, incluindo `eua`) para 12 arquivos. Sem bandeira, a Web mostra um ⚽ (`Views/Shared/_Time.cshtml`). O app copia essa tabela e esse comportamento.
- **`mexico.svg`, `serbia.svg` e `uruguay.svg` definem as cores em um bloco `<style>` com classes, e o `flutter_svg` ignora esse bloco** (o log diz `unhandled element <style/>`). O teste mostrou o escudo da Sérvia, o sol do Uruguai e a águia do México em preto. Os três países estão nos jogos do seed.
- `mexico.svg` é o arquivo pesado (159 KB, 67 ms para interpretar no teste, no PC). As outras 11 somam cerca de 46 KB.
- `logo.png` tem 1536×1024 e 241 KB, bem mais do que o app precisa. A proporção 3:2 pede um recorte quadrado para o ícone (passo 2A.6).

---

## 4. Decisões sobre as dúvidas de produto

Respondidas em 07/11/2026. Não há dúvida em aberto. As referências "decisão 4.x" no resto do documento apontam para esta tabela.

| # | Dúvida | Decisão | Onde entra |
|---|---|---|---|
| 4.1 | Ingresso de jogo que já passou e não foi usado | **Terceiro selo "Expirado" no app**, com o `.selo-vermelho` do site: ingresso não utilizado cujo jogo já passou, pela data do jogo (decisão 4.4). A Web continua com dois selos | Passos 2C.2, 2C.7 e 2D.3 |
| 4.2 | Tolerância depois do início do jogo | **Sem tolerância.** Quem chega depois do início é recusado, e o cartão troca de jogo nesse instante | Passo 1.5 |
| 4.3 | A Portaria não sabe qual jogo está acontecendo | **Aceita qualquer jogo futuro**, porque a demonstração depende disso. A resposta traz também `DataJogo`, para quem está na portaria conferir o dia | Passos 1.3 e 1.5 |
| 4.4 | Data do jogo alterada depois da venda | **Valida pela data atual do jogo (`Jogo.DataHora`), não por `QRCode.DataExpiracao`.** Uma mudança de data vale na hora, sem sincronizar nada. O próximo jogo e o selo Expirado do app também usam a data do jogo | Passos 1.5, 1.8 e 2C.2 |
| 4.5 | Novas datas do seed | **De 14 a 19/12/2026, às 16:00**, um jogo por dia, na ordem atual: México x Canadá (14), Estados Unidos x Uruguai (15), Brasil x Sérvia (16), Argentina x Dinamarca (17), França x Chile (18) e Alemanha x Japão (19) | Passo 1.8 |
| 4.6 | Rota da consulta periódica | **Reusa `GET /api/vendas/meus-ingressos`** e filtra por `ingressoId`, a cada 5 segundos. Trocar depois afeta só um método do serviço | Passo 2D.4 |
| 4.7 | Onde fica a Portaria para o `ADMIN` | **Na mesma tela inicial**, com um botão "Portaria" na barra superior, porque ele também pode ter ingressos | Passos 2C.3 e 2E.1 |
| 4.8 | Lista de outros ingressos | **Todos menos o do cartão**, inclusive usados e passados, na ordem da Api. Tocar em um deles abre o QR dele | Passo 2C.7 |
| 4.9 | Aparelhos de teste | **Corrigida em 07/11/2026: o emulador Android é o aparelho principal**, porque o celular do responsável é um iPhone e a máquina é Windows. O Edge é o plano B. O Android de um colega fica para as capturas e a apresentação. A câmera do emulador não serve para ler um QR real, então os testes usam o campo de código (decisão 4.10) | Passos 2A.1, 2E.7 e 3.8, seção 8 |
| 4.10 | Digitar o código na Portaria | **Entra:** um campo para digitar ou colar o código, como alternativa à câmera, passando pela mesma validação | Passo 2E.3 |
| 4.11 | Sem rede ou com o token vencido na portaria | **O QR já aberto continua visível sem rede**, com um aviso. O 401 leva ao login, e o QR some junto. Sem modo offline | Passo 2D.4 |
| 4.12 | LIBRAS (Etapa 8) | **O app não traz conteúdo em LIBRAS.** `Semantics` atende leitores de tela, não LIBRAS. O documento registra que as respostas são visuais (cor, ícone e texto, sem depender de som), e a proposta em si fica com quem responde pela Etapa 8 | Passo 3.6 |
| 4.13 | Personas e wireframes (Etapa 6) | **Ficam com quem responde pela Etapa 6.** Este plano entrega os fluxos, as capturas e as melhorias encontradas | Passo 3.6 |
| 4.14 | Nome e ícone do app | **O logo do site é o ícone**, gerado com `flutter_launcher_icons` só como `dev_dependency`, e o rótulo é "Mundial Tickets". O `applicationId` `com.example.mobile` continua, porque o app não será publicado | Passo 2A.6 |
| 4.15 | Texto do aviso no login | **"O cadastro e a compra de ingressos são feitos no site Mundial Tickets."** Sem link, porque o site só tem endereço local | Passo 2B.6 |

---

## 5. Passo a passo

A cada passo, o critério "Pronto quando" diz como verificar. Antes de cada parte: `git status` limpo, na branch `feature/mobile-app`. Ao fim de cada parte com Flutter: `flutter analyze` sem avisos e `flutter test` passando. Decisões tomadas durante a execução entram em "Notas", como no plano do C#.

### Fase 1: backend (dados do cartão, validação do ingresso, datas futuras e contas de teste)

Autorizada só para o que está aqui, em commit separado. Seguir a arquitetura em camadas do manual e o tom didático dos comentários. Rodar `dotnet build backend/MundialTickets.sln` com a Api e a Web paradas.

- [x] **1.1** `IngressoCompradoDto`: acrescentar `TimeA`, `TimeB`, `EstadioNome` e `EstadioCidade`, os mesmos nomes do `JogoDto`. `Partida` continua, porque a Web usa. A mudança só acrescenta campos, e a Web segue compilando. Ajustar o comentário da classe, que lista as tabelas consultadas.
- [x] **1.2** `VendaRepositorio.ListarIngressosDoUsuario`: preencher os campos novos na projeção, por `q.Ingresso.Jogo` e `q.Ingresso.Jogo.Estadio`. *Pronto quando:* a rota devolve os quatro campos e a página Meus Ingressos da Web continua igual.
- [x] **1.3** Criar em `Modelos/Dtos`: `IngressoValidarDto` (entrada: `CodigoQR`, obrigatório, até 255 caracteres, com mensagem em português) e `IngressoValidadoDto` (saída: `IngressoId`, `Partida`, `DataJogo`, `NomeSetor`, `NumeroAssento`).
- [x] **1.4** `IVendaRepositorio` e `VendaRepositorio`, que já é a "única classe que conversa com Venda, ItemVenda e QRCode":
  - `ObterQRCodePorCodigo(codigo)`: `AsNoTracking`, com `Ingresso`, `Jogo` e `Setor`;
  - `MarcarQRCodeComoUtilizado(codigo)`: `ExecuteUpdate` com `Where(CodigoQR == codigo && !Utilizado)`, devolvendo se alterou uma linha. Esse `UPDATE` único é a garantia contra dois leitores: o segundo espera a trava da linha, relê a condição e altera zero linhas. A consulta é parametrizada pelo EF.

  **Cuidado:** o `ExecuteUpdate` não atualiza entidades já carregadas. Foi o que causou o defeito do `Desativar` (notas da Fase 2 do plano do C#). Por isso a leitura é sem rastreamento e nada lê o objeto de novo depois.
- [x] **1.5** `VendaNegocio.ValidarIngresso(codigoQR)`, nesta ordem, com `RegraDeNegocioException` e estas mensagens **[PROPOSTA]**:
  1. código não existe: "Código não encontrado: este QR não pertence a nenhum ingresso.";
  2. status diferente de `VENDIDO`: "Este ingresso não está vendido.";
  3. `Utilizado` já marcado: "Este ingresso já foi utilizado.";
  4. **`Jogo.DataHora`** menor ou igual a `DateTime.Now`: "O prazo deste ingresso já passou: o jogo já começou." (decisões 4.2 a 4.4);
  5. marca como utilizado. Se nenhuma linha mudou, outro leitor chegou antes: a mesma mensagem do item 3;
  6. devolve o `IngressoValidadoDto`.
- [x] **1.6** `VendasController`: `[HttpPost("validar")]` com `[Authorize(Roles = PerfilUsuario.Admin)]`, sem `try/catch`, porque o `RegraDeNegocioFiltro` já devolve 400. Fica aqui, e não em `IngressosController`, porque usa o `VendaNegocio`. Assim **nenhum registro novo** entra nos dois `Program.cs`.
- [x] **1.7** Acrescentar ao `MundialTickets.Api.http` as chamadas de validação (liberada, repetida, código inexistente, sem token e com token de `CLIENTE`), com o resultado esperado em cada título, como no resto do arquivo. *Pronto quando:* a rota aparece no Scalar, com o cadeado.
- [x] **1.8** `05_Dados_Teste.sql` (decisão 4.5): trocar as datas de `@Jogos`; acrescentar um `UPDATE` de `Jogo.DataHora` para os jogos do seed (por estádio e times); reescrever o cabeçalho, que hoje diz que o arquivo "só insere linhas" e manda rodar em banco limpo. Avisar nele que repetir o script desfaz uma alteração de data feita pelo administrador nesses 6 jogos. `QRCode.DataExpiracao` não é tocada (decisão 4.4).
- [x] **1.9** Registrar as decisões, porque o backend é de outro colega:
  - `docs/Passo_a_passo_CSharp_PIM_IV.md`: uma "Fase 8: apoio ao app mobile", já concluída, com as notas desta fase; a nova rota; a premissa 4.10 atualizada; e o `QRCode` gravado pelo EF;
  - notas locais do projeto: a exceção de `QRCode.Utilizado` na regra de gravação, a rota nova, o plano do app e o motivo do "não filtra por data", que deixa de ser "as datas do seed já passaram";
  - os comentários de `VendaRepositorio` ("não grava nessas tabelas pelo EF") e `JogoNegocio` ("as datas do seed já passaram").
- [x] **1.10** Compilar e aplicar no banco local. *Pronto quando:* `dotnet build` passa e, com o seed rodado duas vezes neste banco já povoado, a conferência continua 7/21/175/6/150, com as 6 datas de dezembro e sem jogo duplicado.
- [x] **1.11** Contas de teste, **só no banco local**, pela Api:
  - um comprador com 3 ingressos comprados com Pix, de jogos diferentes, para a tela inicial e a lista terem conteúdo;
  - uma conta `ADMIN` para a Portaria: cadastro pela Api e depois `UPDATE Usuario SET Perfil = 'ADMIN' WHERE Email = '...'`.

  *Pronto quando:* as duas contas entram pela Api, `meus-ingressos` devolve os 3 ingressos e **nenhum e-mail ou senha foi commitado**. Quem precisar delas recria na própria máquina com este mesmo passo.
- [x] **1.12** Verificar com a Api real, usando a conta `ADMIN` e um comprador temporário, para os 3 ingressos da conta de teste continuarem válidos:

  | Caso | Esperado |
  |---|---|
  | Sem token | 401 |
  | Token de `CLIENTE` | 403 |
  | Código inexistente | 400 com a mensagem |
  | Código em branco | 400 com a mensagem do DTO |
  | Código válido | 200 com partida, setor, assento e data; `Utilizado = 1` no banco |
  | O mesmo código de novo | 400 "já foi utilizado" |
  | Ingresso com status alterado por um `UPDATE` temporário | 400 com a mensagem |
  | `Jogo.DataHora` no passado por um `UPDATE` temporário | 400 com a mensagem |
  | `DataExpiracao` no passado com o jogo no futuro | 200 (prova a decisão 4.4) |
  | **Duas chamadas simultâneas com um código novo** | Exatamente um 200 e um 400 |
  | `meus-ingressos` e a Web depois da validação | Os quatro campos novos, `utilizado: true` e selo Utilizado |
  | `expiraEm` no login | Termina em `Z` |
  | OpenAPI e Scalar | A rota aparece, com o cadeado |

  *Pronto quando:* a tabela passa e, depois de desfazer o que o teste criou, o banco tem só as contas do passo 1.11 e as vendas delas, com os outros ingressos de volta a `DISPONIVEL`.

**Notas da Fase 1 (decisões tomadas durante a execução):**

- **Banco local depois desta fase:** jogos de 14 a 19/12/2026, 2 contas, 3 vendas e 3 QR codes, nenhum utilizado; 147 ingressos `DISPONIVEL` e 3 `VENDIDO`. O comprador de teste tem Brasil x Sérvia (A01, Arquibancada Inferior), França x Chile (C01, Camarote) e Alemanha x Japão (B01, Arquibancada Superior). O próximo jogo é Brasil x Sérvia, no AT&T Stadium, o que já exercita o `&` do passo 2C.8 e a bandeira convertida da Sérvia. E-mails e senhas não estão no repositório.
- **`sqlcmd` precisa de `-I`.** Sem ele, o `INSERT` em `Ingresso` falha com o erro 1934 (`QUOTED_IDENTIFIER`), sem gravar nada. O SSMS já usa esse padrão. O seed foi ensaiado em uma cópia com `ROLLBACK` antes de rodar de verdade, porque um erro de codificação nos acentos duplicaria os jogos.
- **`dotnet run --no-build` exige o caminho do `.csproj`.** Com a pasta do projeto, o SDK 10.0.401 responde "O caminho do arquivo fornecido não existe". Os comandos da seção 8 não usam `--no-build`.
- **As chamadas do `.http` não foram clicadas no editor.** O roteiro de verificação fez as mesmas requisições por HTTP.
- **Verificação:** 28 conferências contra o banco real, com o build sem avisos e sem nenhum `fail:` nos logs da Api e da Web. Duas falharam por defeito do roteiro (acentos codificados no HTML da Web e o Scalar devolvendo HTML, não JSON) e foram reconferidas: a Web mostra as partidas, as datas e os selos certos, e o Scalar responde 200. O comprador temporário foi apagado.

### Fase 2: app completo

Executada em sequência, sem parar entre as partes, com um commit por parte.

#### Parte 2A: base do app (pacotes, tema, assets e configuração)

Nada aqui chama a Api.

- [ ] **2A.1** Conferir o emulador (decisão 4.9). *Pronto quando:* `flutter devices` lista o emulador e o Edge, e o app padrão roda no emulador.
- [ ] **2A.2** No `pubspec.yaml`: a descrição do projeto, os pacotes da seção 2 (sem `cupertino_icons`), os assets e a família Poppins. O `flutter pub get` altera os registrantes gerados de `linux`, `macos` e `windows`, que estão no Git, e eles entram no commit. *Pronto quando:* `flutter pub get` passa.
- [ ] **2A.3** Copiar os assets para `mobile/assets`, sem alterar os originais da Web:
  - `img/logo.png`, reduzido para 768×512;
  - `flags/`: as 12 bandeiras. Nove são cópias diretas. **México, Sérvia e Uruguai passam pelo `svgo`**, que leva as classes do `<style>` para atributos de cada elemento. A conversão é feita uma vez e o resultado entra no Git, então ninguém precisa de Node para compilar:

    ```bash
    npx svgo@4.1.0 --config svgo.config.cjs -i <original>.svg -o mobile/assets/flags/<nome>.svg
    ```

    ```js
    // svgo.config.cjs: testado nas três bandeiras (não fica no repositório)
    module.exports = { multipass: true, plugins: [
      { name: 'preset-default', params: { overrides: {
        inlineStyles: { onlyMatchedOnce: false, removeMatchedSelectors: true },
        cleanupIds: false, removeViewBox: false } } },
      'convertStyleToAttrs', 'removeStyleElement' ] };
    ```
  - `fonts/`: Poppins Regular, Medium, SemiBold, Bold e ExtraBold (cerca de 160 KB cada) e o `OFL.txt` da licença, do repositório `google/fonts`, pasta `ofl/poppins`.

  *Pronto quando:* um teste confere que as 12 bandeiras carregam e que nenhuma contém `<style`, o que protege contra alguém copiar os originais de novo; as três bandeiras convertidas têm as cores certas na tela.
- [ ] **2A.4** Tema: `tema/cores.dart` com os valores da seção 3.5, `tema/tema_app.dart` com o `ThemeData` (Poppins, fundo, botões e campos) e os widgets `CartaoVidro` e `SeloIngresso` (Válido, Utilizado e Expirado), sem `BackdropFilter`. `MaterialApp` em pt-BR (`flutter_localizations`), sem a faixa de debug e travado em retrato. *Pronto quando:* uma tela de exemplo mostra cartão, botão e os três selos no visual do site.
- [ ] **2A.5** Configuração: `config/configuracao_api.dart` lê `String.fromEnvironment('API_URL')`, sem valor padrão e sem IP no código. Vazio mostra uma tela explicando o `--dart-define`. Em build de release, um endereço que não seja `https://` é recusado (ver passo 2A.6). *Pronto quando:* há teste dos três casos e `grep -rE "10\.0\.2\.2|192\.168|localhost" mobile/lib` não encontra nada.
- [ ] **2A.6** Android:
  - no manifesto principal: `INTERNET`, `android:label="Mundial Tickets"`, `android:allowBackup="false"` (o README do `flutter_secure_storage` avisa que o backup causa `InvalidKeyException`) e um `<queries>` para `https`, que o `canLaunchUrl` exige a partir do Android 11;
  - em `src/debug/AndroidManifest.xml`: `android:usesCleartextTraffic="true"`. **Isso não basta:** segundo a documentação do Flutter, a política do Android vale para sockets nativos, e sockets do Dart não são bloqueados. A barreira real é a recusa do passo 2A.5;
  - câmera: **uma permissão de Android vale para o app inteiro, não para uma tela.** O `mobile_scanner` já a declara, com `required=false`. O que este plano garante é que o pedido ao usuário só aparece ao abrir a Portaria (passo 2E.2);
  - ícone (decisão 4.14): `assets/img/icone_app.png`, quadrado, com o logo centralizado sobre `#0d0d0d`, e `dart run flutter_launcher_icons` com `adaptive_icon_background` e `adaptive_icon_foreground`. As imagens geradas entram no commit;
  - iOS: `NSCameraUsageDescription` no `Info.plist`, sem teste.

  *Pronto quando:* o manifesto final (`build/app/intermediates/merged_manifest/`) tem `usesCleartextTraffic` em debug e não em release, e tem `INTERNET` nos dois; o ícone e o rótulo aparecem no emulador; e um APK de release apontando para `http://` mostra a recusa.
- [ ] **2A.7** Limpeza: trocar o `main.dart` e o teste do contador, ativar em `analysis_options.yaml` as regras `prefer_const_constructors`, `prefer_const_literals_to_create_immutables` e `prefer_const_declarations` (o `flutter_lints` 6 não as liga), e atualizar o comando de teste único nas notas locais do projeto. *Pronto quando:* `flutter analyze` e `flutter test` passam e `flutter build apk --debug` gera o APK.

#### Parte 2B: camada de dados e login

- [ ] **2B.1** Modelos em `modelos/`, com `fromJson` escrito à mão: `Usuario` (com `toJson`, para guardar), `Sessao` (`token`, `expiraEm`, `usuario`), `Ingresso` e `IngressoValidado`. `numeroAssento` e `cpf` podem ser nulos; `precoPago` é lido como `num`. *Pronto quando:* há testes com JSON completo, assento nulo, `450` e `450.00`, e com a grafia `codigoQR`.
- [ ] **2B.2** Erros em `servicos/erros_api.dart`: `ApiException` (mensagem e código), `SessaoExpiradaException` e `SemConexaoException`, e a leitura do corpo na ordem da seção 3.2. *Pronto quando:* há teste de cada linha daquela tabela, inclusive corpo vazio e HTML.
- [ ] **2B.3** `ClienteApi`: recebe o `http.Client` e o endereço no construtor, para os testes passarem um falso. Coloca o `Authorization: Bearer`, limita cada requisição a 10 segundos **[PROPOSTA]** e lê o corpo com `utf8.decode(bodyBytes)`, por causa dos acentos. Captura `TimeoutException` e `http.ClientException`, sem importar `dart:io`, para funcionar no Edge. Não registra corpo nem cabeçalho em log.
- [ ] **2B.4** `ArmazenamentoSessao`: interface, implementação com `flutter_secure_storage` e versão falsa para os testes. Guarda `token`, `expiraEm` e `usuario`. **A senha nunca entra.**
- [ ] **2B.5** `AutenticacaoServico` e um `ValueNotifier<Sessao?>` no topo do app:
  - `entrar`: o 401 do login vira mensagem no formulário;
  - `sair`: limpa o armazenamento;
  - `restaurar` ao abrir: sem sessão ou com `expiraEm` vencido, vai ao login. Com sessão válida, `GET /api/usuarios/me` confirma que a conta segue ativa; a falta de rede não derruba a sessão. **O perfil continua o do login**, porque é o que está no token (seção 3.1);
  - antes de cada chamada: token vencido nem sai do aparelho;
  - qualquer 401 fora do login zera o `ValueNotifier`, e o `app.dart` volta ao login, com "Sua sessão expirou".
- [ ] **2B.6** `telas/login_tela.dart`: logo, `Form` com e-mail e senha, as mesmas mensagens do `LoginDto` ("Informe o e-mail.", "E-mail inválido.", "Informe a senha."), `autofillHints`, botão de mostrar a senha, botão desativado com indicador durante o envio, área de erro e o aviso da decisão 4.15. Rolável, para o teclado e fontes grandes não cortarem nada. Controllers descartados no `dispose`.
- [ ] **2B.7** Testes com `MockClient`: login certo, 401 de login, 401 de outra rota derrubando a sessão, 400 com `erro`, 400 com `errors`, 500, tempo esgotado, falha de conexão, token vencido sem requisição e cabeçalho `Authorization`. Testes de widget do login: campos vazios, e-mail inválido e erro da Api.
- [ ] **2B.8** *Pronto quando:* com a Api rodando (seção 8), o login real funciona no emulador e no Edge; senha errada mostra a mensagem da Api; fechar e abrir o app mantém a sessão; e `grep -rnE "SharedPreferences|print\(" mobile/lib` não encontra nada.

#### Parte 2C: tela inicial com o cartão e o mapa

- [ ] **2C.1** `IngressoServico.listarMeusIngressos()`.
- [ ] **2C.2** Funções puras, que recebem `agora` como parâmetro:
  - `situacaoDoIngresso(ingresso, agora)`: `utilizado` dá Utilizado; `dataJogo` menor ou igual a `agora` dá Expirado; o resto dá Válido (decisões 4.1 e 4.4);
  - `separarIngressos(lista, agora)`: o próximo é o de menor `dataJogo` entre os Válidos, desempatando por `ingressoId`. Os demais são os outros.

  *Pronto quando:* há testes com lista vazia, tudo usado, tudo passado, jogo em andamento, usado de jogo passado (fica Utilizado) e dois ingressos do mesmo jogo.
- [ ] **2C.3** `telas/inicio_tela.dart`, com `RefreshIndicator`, porque a compra acontece no site e o app precisa enxergá-la sem reiniciar. Estados: carregando; vazio ("Você ainda não tem ingressos", indicando o site); erro com "Tentar de novo"; tem ingressos, mas nenhum próximo jogo (mensagem no lugar do cartão, lista abaixo). Barra superior com o logo, "Sair" e, só para `ADMIN`, "Portaria" (decisão 4.7).
- [ ] **2C.4** `widgets/cartao_proximo_jogo.dart`: **altura mínima** de 50% da tela, nunca altura fixa, para fonte grande não estourar. Bandeiras e nomes, setor, assento (ou "—", como a Web), data e hora, estádio e cidade, selo, mapa e os botões "Como chegar" e "Validar ingresso".
- [ ] **2C.5** `util/bandeiras.dart`: a tabela de `Bandeiras.cs` e a retirada de acentos à mão, sem pacote. Time desconhecido mostra o ⚽. *Pronto quando:* há teste dos 12 nomes do seed com acento, de `EUA` e de um time desconhecido, e cada arquivo devolvido existe nos assets.
- [ ] **2C.6** `widgets/mapa_rota.dart`: `CustomPainter` com `Path` e `PathMetric.extractPath`, para desenhar a rota aos poucos, até uma bandeira pintada no destino, em repetição com pausa. Usa `repaint: controller`, para não reconstruir widgets a cada quadro, e `RepaintBoundary`. Um rótulo deixa claro que o mapa é ilustrativo. A animação fica parada fora da tela, sem pacote extra:
  - com outra tela por cima, o `Overlay` desliga os tickers (`tickerEnabled: false`, conferido em `overlay.dart` no SDK);
  - com o app em segundo plano, o Flutter não gera quadros;
  - com o cartão fora da lista rolada, a lista preguiçosa descarta o widget e o `dispose` encerra o controller. Um pouco além da borda (a margem do `cacheExtent`), ele ainda roda.

  Com `MediaQuery.disableAnimations`, mostra o desenho pronto, sem animar.
- [ ] **2C.7** Lista dos outros ingressos (decisão 4.8), com cartões compactos e o selo de cada um, inclusive Expirado.
- [ ] **2C.8** "Como chegar": `Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$estadio, $cidade'})` e `launchUrl` com `externalApplication`. **Montar pelo `Uri`, e não concatenando texto:** "AT&T Stadium" está no seed, e o `&` quebraria o endereço. Falha mostra um aviso. *Pronto quando:* há teste de que o `&` sai como `%26`, e o botão abre o estádio certo no emulador.
- [ ] **2C.9** Testes de widget: os quatro estados, "Tentar de novo", campos do cartão e "Portaria" só para `ADMIN`. **Usar `pump(duração)`, e não `pumpAndSettle`,** que nunca termina com uma animação em repetição. *Pronto quando:* a tela mostra os dados reais da conta de teste.

#### Parte 2D: tela do QR Code

- [ ] **2D.1** Hero com a etiqueta `ingresso-$ingressoId`, única por ingresso. **O Hero envolve só o fundo de vidro**, com `Material(type: transparency)`, e o conteúdo da tela nova aparece com um fade. Se o texto ficar dentro do Hero, o voo tende a causar erro de `RenderFlex overflowed` e texto com sublinhado amarelo. *Pronto quando:* o cartão se expande sem erro no console, nas duas direções.
- [ ] **2D.2** `QrImageView` sobre um **quadro branco opaco**, com módulos escuros, margem de silêncio e correção de erro M, usando o `codigoQR` sem alteração. O vidro escuro do tema atrapalharia a leitura da câmera. Lado entre 220 e 320, conforme a tela. Abaixo, o texto do código, como na Web, que também serve para digitar na Portaria.
- [ ] **2D.3** `SeloIngresso` com troca animada e `Semantics(liveRegion: true)`, para o leitor de tela anunciar a mudança. Mostra partida, setor, assento e data. Um ingresso Expirado abre a tela normalmente, com o selo vermelho (decisão 4.1).
- [ ] **2D.4** Consulta periódica (decisões 4.6 e 4.11), com um `Timer` de disparo único, reagendado **depois** que a resposta chega, para nunca sobrepor chamadas. Começa no `initState`, é cancelada no `dispose`, pausa em segundo plano (`WidgetsBindingObserver`) e **só roda enquanto o selo for Válido**: para de vez em Utilizado ou Expirado. Falha de rede não some com o QR: só mostra um aviso discreto. O 401 segue a regra do passo 2B.5. O intervalo vem por parâmetro, para os testes.
- [ ] **2D.5** Ao voltar, a tela inicial recarrega, para o cartão refletir a validação.
- [ ] **2D.6** Testes: serviço falso devolvendo `false` e depois `true` muda o selo; depois disso não há mais chamadas; ingresso Expirado não consulta; o jogo começar com a tela aberta muda para Expirado; fechar a tela cancela o timer (o teste falha com "A Timer is still pending" se não cancelar); falha de rede mantém o QR.
- [ ] **2D.7** *Pronto quando:* com o QR aberto, a chamada de validação do `.http` muda o selo em até 5 segundos, e a contagem de chamadas no log da Api mostra que as consultas param ao fechar a tela.

#### Parte 2E: modo Portaria

- [ ] **2E.1** `telas/portaria_tela.dart`, aberta pelo botão da tela inicial. A verificação no app só decide o que mostrar; quem protege é a Api. Se a Api responder 403, avisa e sugere entrar de novo (seção 3.1).
- [ ] **2E.2** `MobileScanner` com o controller criado só nesta tela e descartado no `dispose`, para o pedido de câmera aparecer apenas aqui. Permissão negada (`MobileScannerErrorCode.permissionDenied`) mostra uma explicação no lugar da câmera, e o campo do passo 2E.3 continua funcionando. Em segundo plano, a câmera para, seguindo a seção "Lifecycle changes" do README do pacote.
- [ ] **2E.3** Máquina de estados simples: `lendo`, `validando`, `resultado`. Dois caminhos levam à **mesma validação**: a câmera e um campo para digitar ou colar o código (decisão 4.10). O campo tira os espaços das pontas e não envia vazio. **O `onDetect` é ignorado fora de `lendo`.** A câmera detecta o mesmo QR repetidamente: sem essa trava, a segunda leitura trocaria o verde por um vermelho de "já utilizado". O botão "Ler próximo" limpa o campo e volta a `lendo`.
- [ ] **2E.4** `IngressoServico.validar(codigo)`, com `POST /api/vendas/validar`. O 400 vira recusa com o `erro` da Api.
- [ ] **2E.5** Resultado em tela cheia, com cor, ícone e texto juntos, sem depender só da cor, e `Semantics(liveRegion: true)`:
  - verde `#277234` com texto branco: "Entrada liberada", partida, setor, assento e data;
  - vermelho `#ff4d4d` com texto `#0d0d0d`: "Entrada recusada" e o motivo;
  - **falha de rede ou tempo esgotado não é recusa:** usa uma terceira aparência, neutra, com "Não foi possível validar. Tente de novo.".

  Vibração com `HapticFeedback`, que já vem no Flutter.
- [ ] **2E.6** Testes de widget, com o leitor trocado por um falso (a câmera não existe no teste): liberado, recusado com motivo, falha de rede, duas detecções seguidas gerando **uma** chamada, código digitado passando pela mesma chamada, campo vazio sem chamada, e "Ler próximo".
- [ ] **2E.7** *Pronto quando:* no emulador (decisão 4.9), o `ADMIN` valida pelo campo de código o ingresso de um comprador; o verde aparece; a segunda tentativa fica vermelha, com o motivo; o selo do comprador vira Utilizado; e um `CLIENTE` não vê o botão. A leitura pela câmera fica para o passo 3.8.

### Fase 3: acabamento (responsividade, acessibilidade, testes, capturas e README)

- [ ] **3.1** Responsividade: testes de widget das telas principais em 320×568, 360×640, 390×844 e 430×932 (`tester.view.physicalSize`), com escala de fonte 1,0, 1,3 e 2,0. Um estouro de layout faz o teste falhar. `SafeArea` em todas. Em retrato, como pedido.
- [ ] **3.2** Acessibilidade: `Semantics` no cartão (frase completa do jogo), no mapa (imagem com rótulo), no QR, nos selos, nos botões e na câmera. Bandeira ao lado do nome fica fora da leitura, como o `alt=""` da Web. Texto respeita o tamanho do sistema. Contraste segundo a seção 3.5. *Pronto quando:* passam `androidTapTargetGuideline`, `labeledTapTargetGuideline` e `textContrastGuideline`, e um percurso com TalkBack chega do login ao QR.
- [ ] **3.3** Desempenho: revisar `const`, `dispose` de controllers e timers, e `RepaintBoundary`. Medir no DevTools, em `--profile` e no Android do colega (o modo profile não roda em emulador): abertura da tela com bandeiras, mapa e Hero. Se o `mexico.svg` causar engasgo, pré-compilar com o transformador do `vector_graphics_compiler`. Logo com `cacheWidth`. *Pronto quando:* os números e a conclusão estão nas notas da fase.
- [ ] **3.4** Testes: conferir que modelos, serviços e telas principais estão cobertos e que não restou código do contador. *Pronto quando:* `flutter analyze` não tem avisos e `flutter test` passa, com o resultado copiado para as notas.
- [ ] **3.5** Documentação: reescrever o `mobile/README.md`, explicando o que é o app, **como rodar** (o conteúdo da seção 8) e como testar. Atualizar a parte "Mobile" e os comandos das notas locais do projeto, e passar o desenho do app para o diagrama do passo 7.2 do plano do C#.
- [ ] **3.6** Evidências para o documento, em `docs/capturas_mobile/`: login, tela inicial, ingressos vazios, erro com "Tentar de novo", QR Válido, QR Utilizado, QR Expirado, Portaria verde, Portaria vermelha, a tela inicial em aparelho pequeno e grande, e com fonte grande. Mais o desenho do fluxo de navegação.

  | Etapa do manual | O que ela pede | O que este plano entrega |
  |---|---|---|
  | 6 (UX e UI) | Personas, fluxos de navegação, wireframes ou protótipos e análise de usabilidade | Fluxo, capturas e melhorias encontradas (decisão 4.13) |
  | 8 (LIBRAS) | Proposta de acessibilidade com princípios de LIBRAS | Registro do passo 3.2 e das respostas visuais (decisão 4.12) |
  | 9 (Mobile) | Telas responsivas, adaptação a dispositivos, integração com o back-end e capturas | Fases 2 e 3 |
- [ ] **3.7** Roteiro de demonstração, testado do início ao fim, com as contas do passo 1.11: entrar como comprador no Edge; entrar como `ADMIN` no emulador ou no Android do colega; validar; ver o selo mudar; tentar de novo e ver a recusa. *Pronto quando:* o roteiro roda sem ajuste manual fora do que está escrito.
- [ ] **3.8** Android de um colega (decisão 4.9): instalar o app e acessar a Api pela seção 8. *Pronto quando:* a câmera lê o QR mostrado no Edge, a Portaria fica verde e, na segunda leitura, vermelha; e as capturas da apresentação estão feitas.

---

## 6. Ordem de commits

Na branch `feature/mobile-app`, no padrão do histórico, com um commit por parte. O commit do backend contém só `backend/`, `5.database/`, o plano do C# e as notas locais do projeto.

| Ordem | Fase | Mensagem sugerida |
|---|---|---|
| 1 | Este plano | `Doc: plano do app mobile` |
| 2 | Fase 1 | `Add: validação de ingresso na Api, dados do cartão em meus-ingressos e datas futuras no seed` |
| 3 | Fase 1 | `Doc: Fase 1 do plano mobile concluída` (passos marcados e notas) |
| 4 | Parte 2A | `Add: base do app Flutter com pacotes, tema, assets e configuração` |
| 5 | Parte 2B | `Add: camada de dados e login do app` |
| 6 | Parte 2C | `Add: tela inicial do app com o cartão do próximo jogo e o mapa animado` |
| 7 | Parte 2D | `Add: tela do QR Code com consulta periódica da situação` |
| 8 | Parte 2E | `Add: modo Portaria com leitura pela câmera e código digitado` |
| 9 | Fase 3 | `Att: responsividade, acessibilidade, testes, capturas e README do app` |

## 7. Riscos já identificados

- **A câmera só será testada no fim.** O emulador não serve para ler um QR real, então a leitura depende do Android de um colega (passo 3.8). Até lá, o campo de código exercita a mesma validação.
- **Senha e token trafegam sem criptografia na demonstração.** O HTTP só é aceito em debug. No emulador e pelo `adb reverse` isso fica dentro do PC ou no cabo USB, mas pelo IP do PC passa pelo Wi-Fi. Usar só contas de teste.
- **`0.0.0.0` expõe a Api em modo Development à rede local,** inclusive o Scalar. Quando usar esse caminho, a regra de firewall (seção 8) fica restrita ao perfil de rede privada, e a Api deve ser encerrada depois.
- **A demonstração roda em debug,** porque o build de release recusa `http://` e a Api local não tem certificado confiável para um aparelho. O app em debug é mais lento que em release.
- **Resposta perdida na Portaria.** Se a validação for gravada e a resposta se perder por tempo esgotado, a nova leitura diz "já utilizado". A aparência neutra do passo 2E.5 evita concluir errado, mas quem está na portaria precisa saber disso.
- **Captura de tela do QR:** vale a primeira validação. O código não muda, e o banco não guarda a hora em que foi usado.
- **Selos diferentes no site e no app.** Um ingresso passado e não usado aparece como "Válido" na Web e "Expirado" no app (decisão 4.1).
- **Chave do JWT no `appsettings.json`** (risco aceito na seção 7 do plano do C#). Agora ela também permitiria forjar um `ADMIN` que gasta ingressos.
- **Token no Edge:** o README do `flutter_secure_storage` chama a versão web de experimental, com os dados no `localStorage`, e só funciona em HTTPS ou `localhost`. O Edge serve para desenvolver e mostrar o QR, não como uso real.
- **`qr_flutter` sem atualização desde 2023.** Funcionou com o Flutter 3.47.9. Plano B: o pacote `qr`, que ele já usa, com um `CustomPainter`.
- **Relógios diferentes:** o app escolhe o próximo jogo pelo relógio do aparelho, e a Portaria decide pelo do servidor. Podem discordar perto do início do jogo.
- **Tamanho do app:** o `mobile_scanner` acrescenta de 3 a 10 MB (README). A versão que baixa pelo Google Play Services reduz isso, mas exige o serviço no aparelho. O APK de debug do teste teve 178 MB, o que não representa o de release.

---

## 8. Como rodar contra a Api local

A partir da raiz, com o banco no ar. **Use o perfil `http`.** O perfil `https` também abre a porta 7077, o que dá ao `UseHttpsRedirection` para onde redirecionar, e um aparelho não confia no certificado de desenvolvimento (não testado).

| Alvo | Api | App (a partir de `mobile/`) | Situação |
|---|---|---|---|
| **Emulador Android** (principal) | `dotnet run --project backend/MundialTickets.Api --launch-profile http` | `flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:5218` | **Testado.** `10.0.2.2` é o `localhost` do PC visto de dentro do emulador |
| Edge (plano B, e para mostrar o QR do comprador) | Igual ao emulador | `flutter run -d edge --dart-define=API_URL=http://localhost:5218` | CORS conferido. A leitura pela câmera não foi testada |
| Android de um colega, por USB | Igual ao emulador | `adb reverse tcp:5218 tcp:5218` e `flutter run -d <celular> --dart-define=API_URL=http://localhost:5218` | O `adb reverse` foi testado no emulador, mas **falta testar no aparelho**. Repetir ao reconectar o cabo |
| Android de um colega, pelo IP do PC | `dotnet run --project backend/MundialTickets.Api --launch-profile http -- --urls http://0.0.0.0:5218` | `flutter run -d <celular> --dart-define=API_URL=http://<IP-do-PC>:5218` | A Api respondeu pelo IP, chamada do próprio PC. **Falta testar a partir do aparelho** |

**No emulador, `10.0.2.2` ganhou do `adb reverse`:** os dois responderam 200 no teste, mas o `10.0.2.2` não pede nenhum passo extra, enquanto o `adb reverse` se perde quando o emulador reinicia. O emulador precisa da virtualização ligada na máquina. O `adb` fica em `platform-tools`, dentro do SDK do Android (`%LOCALAPPDATA%\Android\sdk\platform-tools`).

No caminho pelo IP, o aparelho precisa estar na mesma rede, e o Windows precisa liberar a porta. Em um PowerShell de administrador, uma vez só (comando ainda não executado):

```powershell
New-NetFirewallRule -DisplayName "Mundial Tickets Api" -Direction Inbound -Protocol TCP -LocalPort 5218 -Action Allow -Profile Private
```

O IP do PC aparece em `ipconfig` e muda de uma rede para outra, então não vai para nenhum arquivo do repositório.
