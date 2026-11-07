# Mundial Tickets: app Flutter

O app mostra os ingressos comprados no site e valida a entrada na portaria. Ele não tem cadastro nem compra, e só conversa com o sistema pela Api (`backend/MundialTickets.Api`).

- **Comprador:** entra com a conta do site e vê o cartão do próximo jogo, com bandeiras, setor, assento, data, estádio e um mapa ilustrado. O botão "Como chegar" abre o Google Maps, e "Validar ingresso" abre o QR Code, com o selo Válido, Utilizado ou Expirado.
- **Portaria (perfil `ADMIN`):** tem tela própria. Quem tem esse perfil abre direto nela, depois do login e com a sessão salva, e não vê a tela do torcedor. O botão "Ler QR Code" abre a câmera, e há um campo para digitar ou colar o código. O resultado aparece em tela cheia, em verde (entrada liberada, com partida, setor, assento e data) ou vermelho (com o motivo), e volta sozinho para a leitura em 5 segundos, ou na hora, pelo botão. A tela mostra o contador de entradas liberadas e o histórico da sessão, que fica só em memória e some ao sair.

As telas estão em [`docs/capturas-mobile`](../docs/capturas-mobile), e o plano com as decisões está em [`docs/Passo_a_passo_Mobile_PIM_IV.md`](../docs/Passo_a_passo_Mobile_PIM_IV.md).

## Antes de rodar

| O que | Como |
|---|---|
| Flutter | 3.47.9 ou mais recente (Dart 3.13.7). O primeiro build do Android baixa cerca de 2 GB (NDK e CMake) |
| Emulador | Um AVD do Android Studio aberto. Exige a virtualização (SVM ou VT-x) ligada no firmware e a Plataforma do Hipervisor do Windows |
| Banco | `CopaDoMundoVendas` no SQL Server local, com os scripts de `5.database` (de `00_Banco.sql` a `05_Dados_Teste.sql`, na ordem dos números) |
| VS Code | Extensões **Flutter** e **C#**, com a pasta **raiz do repositório** aberta |
| Contas | Crie uma conta no site ou por `POST /api/usuarios` e compre ingressos no site. Para a Portaria, promova outra conta com `UPDATE Usuario SET Perfil = 'ADMIN' WHERE Email = '...'` e entre de novo |

## Rodar pelo F5 (VS Code)

1. Abra o emulador.
2. Na aba **Executar e Depurar** (Ctrl+Shift+D), escolha a configuração na lista.
3. Aperte **F5**. Para parar, **Shift+F5**.

| Configuração | O que faz |
|---|---|
| **Api + App (emulador)** | Sobe os dois juntos, e parar um encerra o outro. É a do dia a dia |
| App (emulador) | Só o app, com `API_URL=http://10.0.2.2:5218` |
| App (Edge, profile) | Só o app no Edge, com `API_URL=http://localhost:5218`. Serve de plano B e para mostrar o QR do comprador enquanto o emulador faz a Portaria |
| Api (perfil http) | Só a Api, em `http://localhost:5218` (Scalar em `/scalar`) |

As configurações estão em [`.vscode/launch.json`](../.vscode/launch.json).

**Problemas comuns:**

- **O app não acha o aparelho:** a configuração espera o emulador `emulator-5554`, o id do primeiro emulador aberto. Com outro id (veja em `flutter devices`), ajuste o `deviceId` no `launch.json`.
- **Erro ao compilar a Api:** ela já está rodando em outro lugar e bloqueia os arquivos. Pare a outra execução.
- **"Não foi possível falar com o servidor" no app:** a Api não está rodando. Depois de subi-la, toque em "Tentar de novo".
- **O depurador da Api não para em exceções de regra de negócio:** é de propósito. O `launch.json` usa `justMyCode: false`, senão cada recusa da Portaria congelaria a Api. Pontos de parada normais continuam funcionando.

## Rodar pelo terminal

A partir da raiz do repositório:

```bash
dotnet run --project backend/MundialTickets.Api --launch-profile http
```

Em outro terminal, a partir de `mobile/`:

```bash
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:5218   # emulador
flutter run -d edge --dart-define=API_URL=http://localhost:5218            # Edge
```

O endereço da Api não fica no código: sem o `--dart-define`, o app mostra uma tela explicando o que informar. O `10.0.2.2` é o `localhost` do PC visto de dentro do emulador. Em build de release, o app só aceita `https://`. A seção 8 do plano traz também o caminho para um celular físico.

## Testes

```bash
flutter analyze
flutter test
flutter test test/telas/qr_tela_test.dart   # um único arquivo
flutter test --coverage                     # gera coverage/lcov.info
```

Os testes não precisam de banco, Api nem aparelho: o cliente HTTP é falso (`MockClient`). Eles cobrem modelos, serviços, telas, responsividade (4 tamanhos de tela e 3 escalas de fonte) e acessibilidade (área de toque, rótulos e contraste).

## Como o app se liga ao sistema

```
App Flutter ──HTTP/JSON──► Api ──► Negócio ──► Repositório ──► SQL Server
Site (Web)  ───────────────────────► Negócio
```

```
mobile/lib/
  main.dart, app.dart   início do app, tema e decisão entre login e tela inicial
  config/               endereço da Api vindo do --dart-define
  tema/                 cores e ThemeData
  modelos/              Usuario, Sessao, Ingresso, IngressoValidado, RegistroValidacao e a situação do ingresso
  servicos/             ClienteApi (o único que faz HTTP), autenticação, ingressos e armazenamento
  telas/                login, início, QR, Portaria e câmera
  widgets/              cartão de vidro, selo, bandeira, cartões, mapa, leitor, resultado, histórico e estados
  util/                 bandeiras, formatação de data, validação e "como chegar"
```

O estado é simples: `setState` nas telas e um `ValueNotifier` com a sessão. Sem BLoC, pacotes de injeção de dependência ou geradores de código.

## Assets

- **Bandeiras:** `mexico.svg`, `serbia.svg` e `uruguay.svg` foram convertidas com o `svgo`, porque o `flutter_svg` ignora o bloco `<style>` dos originais. Não copie os arquivos da Web por cima: um teste falha se isso acontecer. O comando está no passo 2A.3 do plano.
- **Ícone do app:** é o troféu do logo. Para gerar de novo, a partir de `assets/icone`, use `dart run flutter_launcher_icons`.
- **Fonte:** a Poppins vai dentro do app, com a licença em `assets/fonts/OFL.txt`.
