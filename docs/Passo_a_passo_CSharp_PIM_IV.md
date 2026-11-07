# Passo a passo: parte C# do PIM IV (Mundial Tickets)

Plano para concluir a **Etapa 4** do Manual do PIM IV (C#, POO, ASP.NET Core MVC e Web API) com base no template `unip-template-pim-2-semestre-2026`, já copiado para `backend/` e renomeado para `MundialTickets`.

Este documento só descreve o que fazer. Tudo o que ele afirma sobre o banco, as classes, o template e os HTMLs foi conferido nos arquivos do repositório. O que **não** pôde ser confirmado está na seção 4 e não deve ser implementado antes da resposta.

Fora do escopo deste plano: app Flutter (Etapa 9), UX/UI, Machine Learning, Comunicação/LIBRAS e o texto do PIM. Aqui entra apenas o C#.

---

## Resumo das fases

Marque cada fase aqui quando todos os passos dela (seção 5) estiverem concluídos.

- [x] **Fase 0:** preparação e dados de teste
- [x] **Fase 1:** Modelos
- [x] **Fase 2:** Repositório
- [x] **Fase 3:** Negócio
- [x] **Fase 4:** injeção de dependência
- [x] **Fase 5:** Api
- [x] **Fase 6:** Web
- [ ] **Fase 7:** fechamento e evidências do manual
- [x] **Fase 8:** apoio ao app mobile (validação do ingresso, dados do cartão e datas futuras)

---

## 1. Situação atual (verificada)

| Item | Estado |
|---|---|
| Solution `backend/MundialTickets.sln` | 5 projetos (Modelos, Repositorio, Negocio, Web, Api), .NET 9, compila sem erros nem avisos |
| Referências | Web e Api → Negocio → Repositorio → Modelos |
| Banco `CopaDoMundoVendas` | Instalado no SQL Server 2025 local (instância padrão, `Server=localhost`), 9 tabelas, 3 triggers, 1 procedure, **0 linhas** de dados. `Usuario.Perfil` criada nos scripts `01` e `02` e no banco instalado |
| Connection string | `appsettings.json` da Web e da Api, chave `Padrao`, `Database=CopaDoMundoVendas` |
| Entidade **Estadio** | Pronta em Modelos (entidade e 2 DTOs), Repositório, Negócio e Api (CRUD completo). Testada na Api com o banco real |
| Web | Sem nenhuma página de entidade (as do exemplo `Cliente` e do `Estadio` foram retiradas). Só `Home` e `Privacy` |
| Injeção de dependência | `Program.cs` da Web e da Api registram `EstadioRepositorio` e `EstadioNegocio` |
| Migrations | Removidas. O banco vem dos scripts de `5.database` (`01` a `04`) e o EF Core só **mapeia** as tabelas |
| Classes antigas | `3.Classes/*.cs` (namespace `classesIngressos`) ainda não foram migradas, exceto o `Estadio` |
| HTML/CSS antigos | `1.html` e `2.css`: site estático com dados escritos à mão (ver seção 5, Fase 6) |

---

## 2. Escopo e decisões já tomadas

| Tema | Decisão |
|---|---|
| Criação do banco | Scripts SQL existentes, sem migrations |
| Ordem de trabalho | Camada por camada, **até a Api**; a Web vem depois |
| CRUD | O manual **não exige** CRUD (a palavra não aparece no texto), mas o grupo decidiu ter. Segue a ideia do `Cliente` do template, **cada entidade com as suas individualidades**, para: **Estádio, Setor, Assento, Jogo e Ingresso** (área administrativa) e **Usuário** (os próprios dados) |
| Autenticação | Cookie na Web e JWT na Api, **com dois papéis**: `CLIENTE` e `ADMIN`, guardados na coluna `Usuario.Perfil` (já criada) |
| Área administrativa | Telas e endpoints do CRUD acima, restritos ao papel `ADMIN` |
| Escolha do ingresso (opção C) | O comprador escolhe **o jogo, o setor e o assento**. Cada assento disponível de um jogo é um `Ingresso` |
| Script de dados | `5.database/05_Dados_Teste.sql` **mantido**, para a demonstração partir com jogos, setores, assentos e ingressos prontos. Com o CRUD, ele passa a ser opcional |
| Pagamento | A compra é **apenas uma simulação**, sem gateway real. O Negócio consulta o `IMetodoPagamento` antes de chamar a procedure |
| QR Code | A Api devolve só o texto (`CodigoQR`); quem desenha a imagem é o Flutter. A Web mostra o texto. Nenhum pacote NuGet na Api |
| Carrinho da Web | Guardado na sessão do ASP.NET Core |
| Herança | Classe base abstrata para as formas de pagamento (Pix, Cartão e Boleto derivam dela), todas simuladas |

---

## 3. O que o banco já define (fonte: `5.database/01` a `04`)

Estas regras já existem no banco. O C# deve **respeitá-las e traduzir os erros**, não reescrevê-las.

### Tabelas e colunas

| Tabela | Colunas | Restrições |
|---|---|---|
| **Estadio** | EstadioID (PK), Nome varchar(100), Cidade varchar(100), CapacidadeTotal int | CapacidadeTotal > 0 |
| **Setor** | SetorID (PK), EstadioID (FK), NomeSetor varchar(50), Capacidade int, PrecoBase decimal(10,2) | Capacidade > 0; único (EstadioID, NomeSetor) |
| **Assento** | AssentoID (PK), SetorID (FK), Numero varchar(10) | único (SetorID, Numero) |
| **Jogo** | JogoID (PK), EstadioID (FK), DataHora datetime, TimeA varchar(50), TimeB varchar(50), Fase varchar(30) | único (EstadioID, DataHora) |
| **Usuario** | UsuarioID (PK), Nome varchar(100), Email varchar(150), SenhaHash varchar(255), CPF varchar(14) **nulo**, DataCadastro datetime (default `getdate()`), Ativo bit (default 1), **Perfil varchar(20) NOT NULL (default `CLIENTE`)** | Email único; Perfil ∈ {CLIENTE, ADMIN} |
| **Ingresso** | IngressoID (PK), JogoID (FK), SetorID (FK), AssentoID (FK, **nulo**), NumeroAssento varchar(10) **nulo**, PrecoFinal decimal(10,2), Status varchar(20) (default `DISPONIVEL`), DataCriacao (default `getdate()`) | Status ∈ {DISPONIVEL, RESERVADO, VENDIDO, CANCELADO}; único (JogoID, SetorID, AssentoID) quando AssentoID não é nulo |
| **Venda** | VendaID (PK), UsuarioID (FK), DataVenda (default `getdate()`), ValorTotal decimal(10,2), StatusPagamento varchar(20) (default `PENDENTE`), MetodoPagamento varchar(30) **nulo** | StatusPagamento ∈ {PENDENTE, APROVADO, CANCELADO, ESTORNADO} |
| **ItemVenda** | ItemVendaID (PK), VendaID (FK), IngressoID (FK), PrecoUnitario decimal(10,2) | IngressoID **único** (um ingresso só pode estar em uma venda) |
| **QRCode** | QRCodeID (PK), VendaID (FK), IngressoID (FK), CodigoQR varchar(255), DataExpiracao datetime, Utilizado bit (default 0) | IngressoID único; CodigoQR único |

Chaves estrangeiras (11): Assento→Setor; Ingresso→Assento, Jogo e Setor; ItemVenda→Ingresso e Venda; Jogo→Estadio; QRCode→Ingresso e Venda; Setor→Estadio; Venda→Usuario. Consequências para os CRUDs: não se exclui um estádio com setores ou jogos, um setor com assentos ou ingressos, um jogo ou assento com ingressos, um ingresso já vendido, nem um usuário que já comprou (`FK_Venda_Usuario`). O Negócio deve avisar isso com mensagem clara.

### Triggers (todas em `ItemVenda`, `AFTER INSERT`)

| Trigger | O que faz |
|---|---|
| `trg_ItemVenda_Insert` | Se algum ingresso inserido tiver status nulo ou diferente de `DISPONIVEL`, dá `RAISERROR('Um ou mais ingressos não estão disponíveis para venda.')`; senão marca os ingressos como `VENDIDO` |
| `trg_ItemVenda_UpdateValorTotal` (também em `DELETE`) | Recalcula `Venda.ValorTotal` como a soma de `PrecoUnitario`, para **todas** as vendas afetadas pelo INSERT ou DELETE (corrigida: antes só recalculava a primeira) |
| `trg_ItemVenda_GerarQRCode` | Cria 1 `QRCode` por item: `CodigoQR` = `NEWID()` + `-` + IngressoID; `DataExpiracao` = data/hora do jogo |

### Procedure `sp_RealizarCompra`

- Parâmetros: `@UsuarioID INT`, `@Ingressos VARCHAR(MAX)` (ids separados por vírgula), `@MetodoPagamento VARCHAR(30)`.
- Cria a `Venda` como `PENDENTE`, insere um `ItemVenda` por id (o preço vem de `Ingresso.PrecoFinal`), atualiza a venda para **`APROVADO` sempre** e confirma a transação.
- Devolve um conjunto de linhas com as colunas **`CodigoQR`, `DataJogo`, `Partida`** (`TimeA x TimeB`).
- **Antes** de abrir a transação, valida a lista e recusa com `THROW`: lista vazia (50010), IDs inválidos (50011), ingressos inexistentes (50012) e ingressos repetidos (50013). Não valida o usuário nem a disponibilidade: isso fica por conta da chave estrangeira e da trigger.
- Em erro **dentro da transação**: faz `ROLLBACK` e relança a mensagem com `RAISERROR` (vira uma `SqlException` no C#, número 50000).

### Comportamento da procedure em falha (testado em 31/10/2026 com os scripts atuais, com tudo desfeito depois)

As validações do início usam `THROW` **antes** da transação: nada chega a ser gravado e o número do erro chega ao C#. As demais falhas acontecem dentro da transação e o `CATCH` da procedure as relança com `RAISERROR` (número 50000).

| Situação | Número | O que o SQL devolve |
|---|---|---|
| Lista vazia | 50010 | "Informe ao menos um ingresso para realizar a compra." |
| ID vazio, não numérico ou não positivo | 50011 | "A lista de ingressos contem IDs invalidos ou vazios." |
| Id de ingresso inexistente | 50012 | "Um ou mais ingressos informados nao existem." |
| Mesmo id duas vezes na lista | 50013 | "A lista contem ingressos repetidos." |
| Ingresso `CANCELADO`, com status nulo ou não `DISPONIVEL` | 50000 | "Um ou mais ingressos não estão disponíveis para venda." (mensagem da trigger) |
| Ingresso já vendido, comprado de novo | 50000 | Violação da UNIQUE KEY de `ItemVenda.IngressoID` (mensagem técnica, **não** a da trigger) |
| Usuário inexistente | 50000 | Violação da FK `FK_Venda_Usuario` |

**Consequência para o plano:** a procedure protege os dados (nada fica gravado em falha). As quatro validações do início têm mensagem própria, mas sem acento, e as falhas de dentro da transação são técnicas. Por isso o Negócio **valida antes** de chamar a procedure (passo 3.7), com mensagens nossas, e a camada Repositório trata a `SqlException` como segunda barreira, trocando cada número por uma mensagem em português correto.

---

## 4. Decisões em aberto e premissas

Nenhuma bloqueia a Fase 1. Cada linha diz a partir de qual passo precisa de resposta.

| # | Dúvida | Bloqueia | Premissa usada neste plano |
|---|---|---|---|
| 4.1 | **Individualidades do CRUD de Ingresso.** O preço vem do setor, o status segue regras e um ingresso vendido não pode ser alterado | Passo 3.5 | Listar e filtrar por jogo e status; **gerar em lote** para um jogo; criar individualmente; **editar só o preço** enquanto `DISPONIVEL`; **cancelar** (`CANCELADO`); excluir só se `DISPONIVEL` ou `CANCELADO` e sem venda |
| 4.2 | **Individualidades do CRUD de Assento.** Cadastrar assento por assento é trabalhoso | Passo 3.4 | CRUD normal (listar por setor, criar, editar, excluir) **mais** a criação em lote de um setor (informa a quantidade e o sistema cria os números) |
| 4.3 | **Ingresso sem assento.** O banco aceita `AssentoID` nulo, mas o comprador escolhe o assento (opção C) | Passos 3.5 e 3.6 | O CRUD **exige** o assento ao cadastrar um ingresso, e a tela de compra só lista ingressos com assento |
| 4.4 | **Primeiro administrador.** O cadastro cria `CLIENTE`, e um script SQL não gera o hash da senha | Passos 0.2 e 3.8 | Cadastrar o usuário normalmente e promovê-lo com `UPDATE Usuario SET Perfil = 'ADMIN' WHERE Email = '...'`, deixado comentado no script de dados |
| 4.5 | **Excluir conta de usuário.** O banco impede a exclusão física de quem já comprou | Passo 3.8 | "Excluir conta" desativa o usuário (`Ativo = 0`), e o login recusa usuário inativo |
| 4.6 | **Reserva de assento.** O status `RESERVADO` existe, mas nada o usa. Dois compradores podem escolher o mesmo assento ao mesmo tempo | Passo 3.7 | Não usar reserva. Vale a primeira compra concluída, e o segundo comprador recebe a mensagem "este assento acabou de ser vendido" |
| 4.7 | **Valores do script de dados.** Capacidades, preços, fase e horário dos jogos não existem no HTML (só as datas) | Passo 0.2 | Valores **fictícios e pequenos**, avisados nos comentários do script |
| 4.8 | **Tela de login social** (ícones de E-mail, Facebook e Outlook, que só mostram um aviso) | Passo 6.2 | Não levar para o sistema novo |
| 4.11 | **Bandeiras dos times.** Hoje são arquivos em `4.flags/` ligados aos jogos por classes CSS, e o banco não guarda nada de bandeira | Passo 6.3 | **Decidido:** uma tabela de correspondência na Web (nome do time para o arquivo `.svg`), sem alterar o banco. Time sem bandeira cadastrada mostra um ícone genérico |
| 4.10 | **Datas dos jogos.** As do HTML (junho de 2026) já passaram em relação à data atual, então um filtro por jogos futuros esconderia todos | Passos 2.5, 3.2 e 5.5 | O sistema **não filtra por data**: lista e vende todos os jogos, ordenados por data. **Atualizado na Fase 8:** o seed agora traz os jogos de 14 a 19/12/2026 e acerta as datas em um banco já povoado. A decisão de não filtrar continua |
| 4.9 | **Versões dos pacotes NuGet** (JwtBearer e outros) | Passos 5.2 e 6.1 | Instalar a versão 9.x e confirmar com `dotnet build` |

---

## 5. Passo a passo

Convenção: **[BANCO]** = regra que o banco já impõe; **[PROPOSTA]** = escolha de projeto, a confirmar. A cada passo, o critério "Pronto quando" diz como verificar. Rode `dotnet build backend/MundialTickets.sln` ao fim de cada fase.

### Fase 0: preparação e dados de teste

- [x] **0.1** Confirmar que a solution compila e que o banco responde (`Server=localhost`, `Database=CopaDoMundoVendas`). *Pronto quando:* build sem erros e o SSMS lista as 9 tabelas.
- [x] **0.2** Criar `5.database/05_Dados_Teste.sql` (arquivo novo, **sem alterar os scripts `01` a `04`**), repetível sem duplicar linhas. Conteúdo:
  - **Estádios e jogos**, a partir de `1.html/index.html` (as datas são do HTML; hora e fase são fictícias): México x Canadá (11/06/2026, Estádio Azteca, Cidade do México), Estados Unidos x Uruguai (12/06, SoFi Stadium, Los Angeles), Brasil x Sérvia (15/06, AT&T Stadium, Dallas), Argentina x Dinamarca (16/06, Mercedes-Benz Stadium, Atlanta), França x Chile (17/06, BC Place, Vancouver) e Alemanha x Japão (18/06, MetLife Stadium, Nova Jersey). Os nomes dos times devem seguir o HTML, para casar com as bandeiras.
  - **Setores** de cada estádio, com `PrecoBase` fictício.
  - **Assentos** de cada setor, em quantidade pequena para o script ficar leve. A `Capacidade` do setor deve ser igual ao número de assentos criados **[PROPOSTA]**.
  - **Ingressos**, gerados por um único `INSERT ... SELECT`: um por combinação de jogo e assento do estádio do jogo, com `SetorID`, `AssentoID`, `NumeroAssento = Assento.Numero`, `PrecoFinal = Setor.PrecoBase` e status `DISPONIVEL`.
  - O `UPDATE Usuario SET Perfil = 'ADMIN' WHERE Email = '...'` **comentado**, para promover o primeiro administrador (premissa 4.4).
  *Pronto quando:* o script roda duas vezes seguidas sem erro e sem duplicar; `SELECT COUNT(*)` por tabela confere com o esperado; o índice único (jogo, setor, assento) não reclama.
- [x] **0.3** Corrigir o `5.database/README`, que cita `03_StoredProcedure.sql` e `04_Triggers.sql`; os arquivos reais são `03_Procedure.sql` e `04_Triggers` (sem extensão), e acrescentar o `05_Dados_Teste.sql`. *Pronto quando:* os nomes batem.
- [x] **0.4** Conferir que o `git status` está limpo no `backend/` antes de começar cada fase, para que cada commit contenha uma fase só.

### Fase 1: Modelos (`MundialTickets.Modelos`)

- [x] **1.1** Criar uma entidade por tabela que falta: `Setor`, `Assento`, `Jogo`, `Usuario`, `Ingresso`, `Venda`, `ItemVenda`, `QRCode`. Usar **as colunas e tamanhos da seção 3** e o molde do `Estadio` (propriedades com `set`, `[Required]`/`[StringLength]` onde a coluna for `NOT NULL`). Colunas nulas viram tipo anulável (`int?`, `string?`). `Usuario` inclui o **`Perfil`**. Reaproveitar os nomes de `3.Classes` onde baterem com o banco, e **corrigir** `3.Classes/Setor.cs`, cujas propriedades (`id`, `nome`, `cidade`, `preco`) não existem na tabela.
- [x] **1.2** Adicionar as propriedades de navegação (`Jogo.Estadio`, `Setor.Estadio`, `Assento.Setor`, `Ingresso.Jogo/Setor/Assento`, `Venda.Usuario`, `Venda.Itens`, `ItemVenda.Ingresso`, `QRCode.Venda/Ingresso`).
- [x] **1.3** Migrar `IValidavel` e `IMetodoPagamento`, alinhando os textos aos valores do banco. Hoje `Venda.Pagar` grava `"Pago"`/`"Pendente"`, mas o banco só aceita `APROVADO`/`PENDENTE`/`CANCELADO`/`ESTORNADO` **[BANCO]**. Criar uma classe base abstrata para as formas de pagamento, da qual Pix, Cartão e Boleto derivam. Todas são **simulações**: nenhuma chama serviço externo.
- [x] **1.4** Criar constantes para os status (`DISPONIVEL`, `RESERVADO`, `VENDIDO`, `CANCELADO`; `PENDENTE`, `APROVADO`, `CANCELADO`, `ESTORNADO`) e para os perfis (`CLIENTE`, `ADMIN`) para não espalhar texto solto no código **[PROPOSTA]**.
- [x] **1.5** Criar os DTOs, no molde de `EstadioDto` e `EstadioSalvarDto`:
  - **CRUD:** um DTO de saída e um de entrada (`...SalvarDto`) para `Setor`, `Assento`, `Jogo` e `Ingresso`, com as mensagens de validação em português. O `Estadio` já tem os seus;
  - **Usuário:** cadastro, login, dados do usuário e alteração dos dados;
  - **Comprador:** setor de um jogo (nome, preço e quantidade de assentos disponíveis), assento disponível (ingresso, número e preço), pedido de compra (ids dos ingressos e método de pagamento), resultado da compra (`CodigoQR`, `DataJogo`, `Partida`) e ingresso comprado com o QR.
  **`SenhaHash` nunca entra em DTO de saída**, e o `Perfil` nunca é aceito em DTO de entrada de cadastro.
- [x] **1.6** *Pronto quando:* a camada compila e **não referencia nenhum outro projeto** (requisito do manual).

### Fase 2: Repositório (`MundialTickets.Repositorio`)

- [x] **2.1** *(atenção: não usar `HasDefaultValue` em `Usuario.Ativo` nem em `QRCode.Utilizado`. O EF Core ignora o valor `false` quando a coluna tem padrão no banco, e um usuário criado inativo viraria ativo. Usar `HasDefaultValueSql("GETDATE()")` só nas datas.)* No `AppDbContext`, criar um `DbSet` e o mapeamento de cada entidade (nome da tabela, chave, tamanhos, relacionamentos, valores padrão e índices únicos da seção 3), como o `Estadio` já faz.
- [x] **2.2** Mapear `ItemVenda` com `HasTrigger("trg_ItemVenda_Insert")`, `HasTrigger("trg_ItemVenda_UpdateValorTotal")` e `HasTrigger("trg_ItemVenda_GerarQRCode")`. O manual exige `HasTrigger` em tabela com trigger no EF Core 7+; sem ele, qualquer gravação de `ItemVenda` pelo EF falha.
- [x] **2.3** Criar uma interface e uma classe de repositório, no molde de `EstadioRepositorio`, para `Setor`, `Assento`, `Jogo`, `Ingresso`, `Usuario` e `Venda`. As quatro operações (incluir, consultar, alterar, excluir) onde houver CRUD. Consultas só parametrizadas.
- [x] **2.4** Em cada repositório de CRUD, um método que diz se a entidade **tem vínculos** (como o `PossuiVinculos` do `Estadio`), para o Negócio recusar a exclusão com mensagem clara. Onde já houver entidades mapeadas, preferir consultas do EF à SQL direta (inclusive no `PossuiVinculos` do `Estadio`).
- [x] **2.5** `JogoRepositorio`: listar com o `Estadio`, ordenados por data, e obter um jogo. `SetorRepositorio`: listar os setores de um estádio. `AssentoRepositorio`: listar por setor e inserir vários de uma vez.
- [x] **2.6** `IngressoRepositorio`: listar com filtros (jogo, status), contar e listar os `DISPONIVEL` de um jogo por setor (com o `Assento`), obter vários por id (com `Jogo`, `Setor` e `Assento`) e inserir vários de uma vez.
- [x] **2.7** `UsuarioRepositorio`: incluir, obter por id, obter por e-mail, alterar e desativar.
- [x] **2.8** `VendaRepositorio.RealizarCompra(usuarioId, ids, metodo)`, com **Dapper**, no molde de `BuscarPorNome` do template: pegar a conexão por `_contexto.Database.GetDbConnection()` e chamar `sp_RealizarCompra` com `commandType: CommandType.StoredProcedure`. Os parâmetros se chamam `UsuarioID`, `Ingressos` (`string.Join(",", ids)`) e `MetodoPagamento`, e o resultado mapeia as colunas `CodigoQR`, `DataJogo` e `Partida`. Esta é a evidência da "chamada da stored procedure" que o manual pede.
- [x] **2.9** No `RealizarCompra`, capturar `Microsoft.Data.SqlClient.SqlException` e relançar como `OperacaoNoBancoException` (exceção do próprio Repositório, com mensagem em português e o erro técnico em `InnerException`), como segunda barreira (a primeira é a validação do passo 3.7). As validações da procedure (números 50010 a 50013) e a mensagem da trigger viram mensagens específicas; o resto vira uma mensagem genérica. O **Negócio** captura essa exceção e a converte em `RegraDeNegocioException`.
- [x] **2.10** Consulta de "meus ingressos": ingressos de um usuário com o QR code (`Venda`, `ItemVenda`, `QRCode`, `Jogo`, `Setor`, `Assento`).
- [x] **2.11** *Pronto quando:* o build passa e cada repositório responde contra o banco com os dados do passo 0.2. A única classe que acessa o banco é o Repositório.

**Notas da Fase 2 (decisões tomadas durante a execução):**

- **A exceção do Repositório é nova e não estava no plano.** O passo 2.9 original mandava relançar como erro de negócio, mas a `RegraDeNegocioException` mora no projeto Negócio, que referencia o Repositório, e uma camada de baixo não pode conhecer a de cima. Por isso o Repositório lança a `OperacaoNoBancoException` e o Negócio faz a conversão (passo 3.7).
- **O número do erro depende de onde a falha acontece.** As validações da procedure feitas **antes** de abrir a transação usam `THROW` com número próprio (50010 a 50013) e o número chega ao C#; cada um vira uma mensagem nossa, com acento (as do banco vêm sem acento). Qualquer falha **dentro** da transação (trigger, índice único, chave estrangeira) é relançada pelo `CATCH` com `RAISERROR` e perde o número original (vira 50000): aí a distinção é pelo **texto** da trigger ("não estão disponíveis"), escrito em português no script do banco, e o resto vira "Não foi possível concluir a compra. Algum dos ingressos pode ter acabado de ser vendido. Tente novamente."
- **O banco local foi sincronizado com os scripts de 31/10** (procedure com validações e as triggers corrigidas, commits do Caique Moraes). Os scripts `03_Procedure.sql` e `04_Triggers` usam `CREATE`, então a sincronização apagou e recriou a procedure e as 3 triggers (sem vendas no banco). O `04_Triggers` termina com `USE [master]` e `ALTER DATABASE ... SET READ_WRITE`, um rodapé do SSMS que o SQL Server não aceita dentro de uma transação: ao aplicar o script em uma transação, esse rodapé precisa ser pulado. Em uma execução normal no SSMS ele não causa problema.
- **O Dapper participa da transação aberta no contexto** (`transaction: _contexto.Database.CurrentTransaction`). Sem isso, a chamada da procedure falharia dentro de uma transação do EF.
- **Não há `AssentoRepositorio` com consultas de disponibilidade**: quem sabe o que está disponível é o `IngressoRepositorio` (`ListarDisponiveis` e `ContarDisponiveisPorSetor`), que só considera ingressos com assento (premissa 4.3).
- **`ObterPorId` devolve a entidade rastreada** (para o Negócio alterar e chamar `Atualizar`); as listagens usam `AsNoTracking`. O `Usuario.Desativar` carrega o usuário e grava `Ativo = false` pelo rastreador. A primeira versão usava `ExecuteUpdate` (um UPDATE direto), que deixava a entidade já carregada no mesmo contexto ainda "ativa": o teste da Fase 3 mostrou uma conta desativada ainda conseguindo comprar, e foi corrigido.
- **As chaves estrangeiras do mapeamento usam `OnDelete(Restrict)`**, espelhando o banco (as FKs dele recusam a exclusão, não apagam em cascata).
- **Os repositórios ainda não estão registrados na injeção de dependência**: isso é a Fase 4.
- Testado contra o banco real, com os dados de teste carregados, por um programa fora do repositório (75 verificações, todas dentro de transações desfeitas, repetidas depois da sincronização com os scripts do banco de 31/10). Isso incluiu o `HasTrigger`: o EF gravou um `ItemVenda` e as três triggers rodaram. O banco ficou com os dados de teste (7 estádios, 21 setores, 175 assentos, 6 jogos e 150 ingressos) e sem usuários, vendas, itens nem QR codes.

### Fase 3: Negócio (`MundialTickets.Negocio`)

Uma classe por área, no molde de `EstadioNegocio`, lançando `RegraDeNegocioException` com mensagem clara.

- [x] **3.1** `SetorNegocio` (CRUD): capacidade > 0 **[BANCO]**; nome único por estádio **[BANCO]**; o estádio precisa existir; a soma das capacidades dos setores não deve passar a `CapacidadeTotal` do estádio **[PROPOSTA]**; não excluir setor com assentos ou ingressos **[BANCO]**.
- [x] **3.2** `JogoNegocio` (CRUD): estádio existente; (estádio, data e hora) único **[BANCO]**; `TimeA` diferente de `TimeB` **[PROPOSTA]**; não excluir jogo que já tem ingressos **[BANCO]**. Para o comprador: listar os jogos, ordenados por data.
- [x] **3.3** `EstadioNegocio`: já existe (capacidade > 0, nome único por cidade, bloqueio de exclusão com vínculos).
- [x] **3.4** `AssentoNegocio` (CRUD, premissa 4.2): setor existente; número único por setor **[BANCO]**; o total de assentos do setor não deve passar a `Capacidade` **[PROPOSTA]**; criação em lote de um setor; não excluir assento com ingresso **[BANCO]**.
- [x] **3.5** `IngressoNegocio` (CRUD, premissas 4.1 e 4.3): jogo, setor e assento existentes; o assento pertence ao setor e o setor ao estádio do jogo; (jogo, setor, assento) único **[BANCO]**; `PrecoFinal` vem do `PrecoBase` do setor; gerar em lote para um jogo (um ingresso por assento do estádio, sem repetir os que já existem); cancelar; não alterar nem excluir ingresso `VENDIDO` **[BANCO: está em `ItemVenda`]**. Para o comprador: listar os **setores de um jogo com preço e vagas**, e os **assentos disponíveis de um setor**.
- [x] **3.6** Hash de senha **[PROPOSTA]**: PBKDF2 com `Rfc2898DeriveBytes.Pbkdf2` (já faz parte do .NET, sem pacote), com sal aleatório, guardando iterações, sal e hash em um único texto que caiba em `varchar(255)`. A senha em texto puro nunca é gravada nem registrada em log.
- [x] **3.7** `VendaNegocio.Comprar(usuarioId, ids, metodoPagamento)`. Validar nesta ordem, **antes** de chamar a procedure:
  1. lista não vazia **[BANCO: a procedure falha com mensagem técnica]**;
  2. sem ids repetidos **[BANCO: UNIQUE em `ItemVenda.IngressoID`]**;
  3. usuário existe e está ativo;
  4. todos os ingressos existem **[BANCO: senão `PrecoUnitario` fica NULL]**;
  5. todos estão `DISPONIVEL` **[BANCO: trigger]**; se algum deixou de estar, a mensagem diz qual assento foi vendido (premissa 4.6);
  6. método de pagamento conhecido, escolhendo a implementação de `IMetodoPagamento`;
  7. calcular o total pela soma de `PrecoFinal` e chamar `ProcessarPagamento` (simulado);
  8. se aprovado, chamar `RealizarCompra` do repositório e devolver os dados da compra. Se não aprovado (por exemplo, Boleto), **nada é gravado** e o usuário recebe um aviso. Essa escolha mantém a procedure intacta, porque ela sempre grava `APROVADO`.
  Também: "meus ingressos" de um usuário, com o código do QR.
- [x] **3.8** `UsuarioNegocio` (CRUD do próprio usuário): **cadastrar** com e-mail único **[BANCO]**, nome e senha obrigatórios e confirmação de senha conferida, **sempre com o perfil `CLIENTE`** (nunca aceita `ADMIN` vindo da tela ou do corpo da requisição); CPF é opcional, como no banco, e quando informado só com dígitos e com 11 **[PROPOSTA, no molde do `Cliente` do template]**; **autenticar** (confere o hash e recusa usuário inativo); **obter** e **alterar** os próprios dados; **excluir conta** como desativação, `Ativo = 0` (premissa 4.5). Promover alguém a `ADMIN` não é função do sistema (premissa 4.4).
- [x] **3.9** Entregar a POO que o manual cobra: encapsulamento (propriedades e regras nas classes), polimorfismo (`IMetodoPagamento` com as 3 formas) e herança (classe base abstrata do passo 1.3).
- [x] **3.10** *Pronto quando:* o build passa e nenhuma regra está em controller ou view. Cada falha da tabela da seção 3 vira uma mensagem clara, **sem chegar à procedure**.
**Notas da Fase 3 (decisões tomadas durante a execução):**

- **Hash de senha:** PBKDF2 com SHA-256, 100.000 iterações, sal de 16 bytes e hash de 32 bytes, guardados como `iterações.sal.hash` (cerca de 80 caracteres). A conferência usa comparação em tempo constante. Texto guardado fora do formato devolve "não confere", sem lançar erro.
- **As classes de Negócio são concretas** (como o `EstadioNegocio`), todas síncronas; só o `IHashDeSenha` tem interface. O `VendaNegocio` recebe um `IEnumerable<IMetodoPagamento>`: **a Fase 4 precisa registrar as três formas de pagamento** (Pix, Cartão e Boleto), além dos repositórios e dos negócios.
- **Regras acrescentadas ao implementar** (não estavam no plano): a capacidade de um setor não pode ficar menor que o número de assentos que ele já tem; não se troca o estádio de um setor com assentos ou ingressos, nem o setor de um assento com ingresso; conta desativada não altera os dados nem compra; o ingresso exige preço maior que zero (o banco aceitaria zero).
- **Login:** a mensagem é a mesma para e-mail desconhecido e senha errada ("E-mail ou senha incorretos."), e o aviso de conta desativada só aparece depois que a senha está certa. O cadastro ignora o `Perfil` que vier de fora e grava sempre `CLIENTE`. O CPF, quando informado, fica só com os dígitos e precisa ter 11; os dígitos verificadores **não** são conferidos.
- **Criação de assentos em lote:** cria `prefixo` + número com dois dígitos (A01, A02...), ou mais se a quantidade pedir. O prefixo é opcional (padrão "A", só letras e números), os números que o setor já tem são pulados, e ou entram todos ou nenhum.
- **Geração de ingressos:** pode ser repetida sem duplicar (devolve quantos criou, inclusive zero). Recusa estádio sem setores, estádio sem assentos e setor com preço base zero.
- **Compra:** a forma de pagamento é reconhecida sem diferenciar maiúsculas e é gravada com o nome padrão (`PIX`, `Cartao`, `Boleto`). Se o banco recusar a compra depois de todas as conferências (por exemplo, outro comprador levou o assento), a `OperacaoNoBancoException` vira uma `RegraDeNegocioException` com a mesma mensagem e o erro técnico em `InnerException`.
- **Limitação do `EstadioNegocio` (resolvida na Fase 4):** ele não conferia a capacidade total do estádio contra a soma dos setores quando o estádio era alterado. Agora o `EstadioNegocio` recebe também o `ISetorRepositorio` e recusa a alteração que deixaria a capacidade total abaixo da soma.
- Testado contra o banco real, com os dados de teste, por um programa fora do repositório (140 verificações, todas dentro de uma transação desfeita). O banco ficou com os dados de teste e sem usuários, vendas, itens nem QR codes.

### Fase 4: injeção de dependência

- [x] **4.1** Para cada repositório e cada classe de negócio novos, acrescentar o `AddScoped` **nos dois** `Program.cs` (Web e Api), mantendo os blocos iguais. A ausência de um deles faz o sistema não subir (erros descritos no `INJECAO-DE-DEPENDENCIA.md`).
- [x] **4.2** *Pronto quando:* a Api e a Web sobem sem a mensagem `Unable to resolve service`.
**Notas da Fase 4 (decisões tomadas durante a execução):**

- **Os registros ficam escritos, linha por linha, no `Program.cs` da Web e da Api** (como no template e como o manual descreve), em um bloco **idêntico** nos dois: 1 `AddDbContext`, 7 repositórios, o hash e as 3 formas de pagamento, e 7 negócios (19 registros). Os dois arquivos de projeto continuam respeitando a direção do manual: a Api referencia só Modelos e Negócio, e a Web só o Negócio.
- **Tempo de vida:** repositórios, negócios e o contexto do banco são `AddScoped` (um por requisição). O hash de senha e as formas de pagamento não guardam estado, por isso são `AddSingleton`. As três formas de pagamento são registradas para o mesmo contrato `IMetodoPagamento`, e é isso que faz o `VendaNegocio` receber as três.
- **`EstadioNegocio` passou a depender também do `ISetorRepositorio`**, para conferir a capacidade total contra a soma dos setores.
- **Máquinas sem o .NET 9:** esta máquina só tem o .NET 10. Os projetos Web e Api do template já têm a opção `RollForward`, que usa o .NET 10 quando o 9 não está instalado. Um projeto novo precisaria dela também.
- **Verificação (4.2):** (1) a Api e a Web foram iniciadas em Desenvolvimento, onde o ASP.NET valida todo o contêiner ao subir, sem nenhum "Unable to resolve service"; (2) o bloco **real** do `Program.cs` foi montado em um programa de teste (22 verificações): todas as classes de Negócio e de Repositório resolveram, o `VendaNegocio` recebeu as 3 formas de pagamento e uma compra completa funcionou só com objetos criados pelo contêiner; (3) na Api rodando, o `PUT` do estádio com capacidade abaixo da soma dos setores devolveu 400 com a mensagem da regra, e com a capacidade original devolveu 204.
- O `INJECAO-DE-DEPENDENCIA.md` da pasta `backend` ainda descreve o exemplo do `Cliente`; ele é reescrito no passo 7.1.

### Fase 5: Api (`MundialTickets.Api`)

- [x] **5.1** Um controller por área, no molde do `EstadiosController`: só DTOs, códigos HTTP corretos (200, 201 com `Location`, 204, 400, 401, 403, 404) e `catch` de `RegraDeNegocioException` devolvendo 400.
- [x] **5.2** Adicionar o pacote `Microsoft.AspNetCore.Authentication.JwtBearer` na Api *(versão a confirmar, premissa 4.9)*.
- [x] **5.3** `POST /api/auth/login`: valida pelo `UsuarioNegocio.Autenticar` e devolve um JWT que leva o `Perfil` do usuário como *claim* de papel (role). A chave de assinatura, o emissor e a validade ficam no `appsettings.json`, **nunca no código**.
- [x] **5.4** Configurar autenticação e autorização no `Program.cs` (`AddAuthentication().AddJwtBearer(...)` e `UseAuthentication()` antes de `UseAuthorization()`).
- [x] **5.5** Endpoints. O `UsuarioID` vem **sempre do token**, nunca do corpo da requisição:

  | Verbo e rota | Acesso | Função |
  |---|---|---|
  | `POST /api/usuarios` | público | cadastrar usuário |
  | `POST /api/auth/login` | público | entrar e receber o token |
  | `GET`, `PUT`, `DELETE /api/usuarios/me` | logado | ver, alterar e desativar a própria conta |
  | `GET /api/jogos` e `GET /api/jogos/{id}` | público | jogos, ordenados por data |
  | `GET /api/jogos/{id}/setores` | público | setores, preço e disponibilidade |
  | `GET /api/jogos/{id}/setores/{setorId}/assentos` | público | assentos disponíveis |
  | `POST /api/vendas` | logado | comprar |
  | `GET /api/vendas/meus-ingressos` | logado | ingressos comprados, com o QR |
  | `POST /api/vendas/validar` | **`ADMIN`** | validar o ingresso na portaria (acrescentada na Fase 8) |
  | `GET`, `POST`, `PUT`, `DELETE /api/estadios`, `/setores`, `/assentos`, `/jogos`, `/ingressos` | **`ADMIN`** | CRUD de administração (e, em `/assentos` e `/ingressos`, a criação em lote e o cancelamento) |

- [x] **5.6** Configurar **CORS** para o app Flutter.
- [x] **5.7** Ajustar o OpenAPI/Scalar para aceitar o token e atualizar o arquivo `MundialTickets.Api.http` com as novas chamadas.
- [x] **5.8** *Pronto quando:* no Scalar ou no `.http` é possível cadastrar usuário, entrar, listar jogos, ver setores e assentos, comprar e ver "meus ingressos" com o QR. Testar também as falhas: assento já vendido, lista vazia, sem token = 401 e token de `CLIENTE` nas rotas de `ADMIN` = 403.
**Notas da Fase 5 (decisões tomadas durante a execução):**

- **Pacote:** `Microsoft.AspNetCore.Authentication.JwtBearer` na versão flutuante `9.*` (resolveu em 9.0.22), como o template faz com o EF Core.
- **O token** leva o id, o nome, o e-mail e o **perfil** do usuário, assinado com HMAC-SHA256, e vale 120 minutos. O `GeradorDeToken` e a configuração do JWT, do CORS e do OpenAPI ficam **só na Api**, em linhas separadas depois do bloco de injeção, que continua idêntico ao da Web.
- **A chave do JWT está no `appsettings.json`** (64 caracteres aleatórios, gerados para este projeto), como o plano mandou. Isso serve para o trabalho acadêmico; em um sistema real, a chave sairia do repositório (variável de ambiente ou *user secrets*).
- **Erros de regra viram 400 por um filtro único** (`RegraDeNegocioFiltro`), em vez de um `try/catch` em cada ação. O `EstadiosController` foi reescrito nesse modelo. O login é a exceção: devolve 401, tratado no próprio `AuthController`.
- **Todas as rotas de administração exigem o perfil `ADMIN`**, inclusive as de estádio, que antes estavam abertas. Só as quatro consultas de jogo (lista, um jogo, setores e assentos disponíveis), o cadastro e o login são públicos. Cadastrar, alterar e excluir jogo são de `ADMIN`.
- **O perfil mora dentro do token.** Quem é promovido a `ADMIN` precisa entrar de novo: o token antigo continua `CLIENTE` (testado). Uma conta desativada depois do login deixa de servir: `GET /api/usuarios/me` devolve 401 e a compra é recusada pelo Negócio. O token em si não pode ser revogado antes de vencer.
- **Rotas acrescentadas ao desenho do plano:** `POST /api/assentos/lote`, `POST /api/ingressos/gerar`, `PUT /api/ingressos/{id}/preco`, `POST /api/ingressos/{id}/cancelar`, `GET /api/assentos?setorId=` (o setor é obrigatório) e `GET /api/setores?estadioId=` (filtro opcional). Quatro DTOs novos: `LoginRespostaDto`, `AssentoLoteDto`, `IngressoGerarDto` e `IngressoPrecoDto`.
- **OpenAPI:** o documento declara o esquema `Bearer` e coloca o cadeado só nas operações protegidas (31 de 37; as 6 públicas ficam sem). O Scalar passa a ter o campo para colar o token.
- **CORS:** a política `AppMovel` libera qualquer origem. Aplicativo instalado no celular não passa por CORS; ela serve ao Flutter rodando no navegador. Em produção, trocar pela lista de origens permitidas.
- **Verificação (5.8):** a Api foi iniciada de verdade e exercitada com `curl` contra o banco real, em duas etapas (comprador e administrador): 132 verificações, das quais 131 passaram; a restante foi um erro do próprio roteiro (procurou o cabeçalho `Location` no corpo da resposta, e a verificação seguinte confirmou o cabeçalho). Cobriu o cadastro (inclusive tentar se cadastrar como `ADMIN`), o login, o 401 e o 403, a compra completa com QR, o CRUD de estádio, setor, assento, jogo e ingresso, as exclusões na ordem das chaves estrangeiras e a desativação da conta. Tudo o que o roteiro criou foi desfeito; o banco ficou com os dados de teste.
- O arquivo `MundialTickets.Api.http` foi reescrito com as chamadas novas, usando o token do login automaticamente.

### Fase 6: Web (`MundialTickets.Web`)

**O que os HTMLs antigos são (conferido em `1.html` e `2.css`).** Site estático, sem back-end. A `index.html` tem banner e carrossel Bootstrap (CDN) com 6 jogos; `INGRESSOS.html` tem a grade dos 6 jogos com bandeiras, campo de **quantidade** e botões "Carrinho" e "Comprar"; `LOGIN.html` e `cadastro.html` só redirecionam; `PAGAMENTO.html` está **vazio**. Não há escolha de setor nem de assento, e nenhum preço aparece. Com a opção C, a quantidade é **substituída** pela escolha do setor e dos assentos.

**Telas do comprador**

- [x] **6.1** Criar **ViewModels** para as telas (o manual recomenda). Os controllers só recebem, chamam o Negócio e devolvem a view. Configurar a autenticação por cookie no `Program.cs` da Web, com o `Perfil` como *claim* de papel (já faz parte do ASP.NET Core), e a sessão para o carrinho.
- [x] **6.2** Telas de **Login** e **Cadastro**, substituindo `1.html/LOGIN.html` e `cadastro.html`. Não levar os defeitos dos HTMLs: o cadastro tem **dois campos com o mesmo `name="Senha"`** (precisam de nomes diferentes, por exemplo `Senha` e `ConfirmarSenha`) e o login aponta para `CADASTRO.html` em maiúsculas, enquanto o arquivo é `cadastro.html`. Os ícones de login social não vão (premissa 4.8), e o texto "Brazil Tickets" do `alt` do logo no login deve ser "Mundial Tickets".
- [x] **6.3** Migrar o visual: `2.css/*.css` para `wwwroot/css`, e de `4.flags/` as bandeiras (`argentina`, `brazil`, `canada`, `chile`, `denmark`, `france`, `germany`, `japan`, `mexico`, `serbia`, `uruguay`, `usa`, todas `.svg`), `jogo.jpeg`, `futebol.jpeg`, `imagem_trofeu_copa.webp` e o logo (`logo 3 - Editado.png`). **Não** copiar o `Claude Setup.exe`, que está na mesma pasta. As bandeiras hoje são escolhidas por uma **classe CSS por jogo** (`.mexico-canada` etc.); com os jogos vindos do banco, o nome do time (`TimeA`/`TimeB`) é ligado ao arquivo da bandeira por uma **tabela de correspondência na Web** (premissa 4.11), sem coluna nova no banco.
- [x] **6.4** Migrar o cabeçalho e o rodapé dos HTMLs para o `_Layout.cshtml` e usar partial views para o que se repete (card de jogo). O menu mostra o item **Administração** só para quem tem o papel `ADMIN`.
- [x] **6.5** **Home** e **Ingressos**: lista de jogos, com o carrossel e os cards (de `index.html` e `INGRESSOS.html`), lendo do banco.
- [x] **6.6** **Escolha do ingresso**: página de um jogo com seus setores (nome, preço e vagas) e, ao escolher um setor, os **assentos disponíveis** para marcar. Os assentos marcados vão para o **carrinho**.
- [x] **6.7** **Carrinho** (guardado na sessão do ASP.NET Core, com os ids dos ingressos) e **Pagamento** (substitui o `PAGAMENTO.html`, hoje vazio): o comprador escolhe Pix, Cartão ou Boleto e a compra chama `VendaNegocio.Comprar`. Exigir login antes de pagar. Mostrar a mensagem de erro do Negócio quando algum assento já foi vendido.
- [x] **6.8** **Meus ingressos**, mostrando o **texto** do código do QR (a imagem é desenhada pelo Flutter).
- [x] **6.9** **Minha conta**: ver, alterar e desativar a conta (CRUD de Usuário).

**Área administrativa** (só o papel `ADMIN`; acesso negado para os demais). **Uma tela por entidade**, com todas as funções do CRUD na mesma página, em vez de `Index`, `Criar`, `Editar` e `Excluir` separados:

- a **tabela** com os registros e, em cada linha, os botões **Editar** e **Excluir**;
- o **formulário** na própria página: vazio, cria; ao clicar em **Editar**, a página recarrega com o formulário preenchido (`?editar=5`) e o mesmo botão passa a salvar a alteração;
- a **exclusão** por um botão com confirmação, sem tela própria; quando recusada por vínculos (seção 3), a mensagem aparece na mesma página;
- os erros de validação e de regra de negócio aparecem junto do formulário;
- o formulário fica numa partial reaproveitada pela página, e a tabela usa `table-responsive`.

- [x] **6.10** Página de **Estádio**, no desenho acima.
- [x] **6.11** Páginas de **Setor** e de **Jogo**, no mesmo desenho, com **lista para escolher o estádio** no formulário.
- [x] **6.12** Página de **Assento**, com lista para escolher o setor e uma segunda seção, **criar vários** (setor e quantidade, premissa 4.2).
- [x] **6.13** Página de **Ingresso** (premissas 4.1 e 4.3): tabela com filtro por jogo e status, o formulário (criar e editar o preço), o botão **gerar para um jogo**, o botão **cancelar** em cada linha e a exclusão.

**Notas da Fase 1 (decisões tomadas durante a execução):**

- Colunas que o banco declara como `NULL` **mas preenche por padrão** (`DataCadastro`, `Ativo`, `DataCriacao`, `DataVenda`, `StatusPagamento`, `Status`, `Utilizado`) viraram propriedades **não anuláveis**, com o mesmo padrão do banco quando há um (`Ativo = true`, `Status = DISPONIVEL`, `StatusPagamento = PENDENTE`). Só viraram anuláveis as que são opcionais de verdade: `Ingresso.AssentoID`, `Ingresso.NumeroAssento`, `Usuario.CPF` e `Venda.MetodoPagamento`.
- `Usuario.Validar()` **não exige CPF**, ao contrário da classe antiga de `3.Classes`, porque o CPF é opcional no banco e no formulário de cadastro.
- `Venda.Pagar(IMetodoPagamento)` da classe antiga **não foi migrado**: quem decide o pagamento é o `VendaNegocio` (passo 3.7). O polimorfismo continua nas três formas de pagamento.
- Nomes dos métodos de pagamento mantidos como nas classes antigas: `PIX`, `Cartao` e `Boleto`.
- As **entidades** seguem os nomes das colunas (`SetorID`, `NomeSetor`...) e os **DTOs** usam `Id`, como o `Estadio`. As classes de `3.Classes` não foram alteradas nem apagadas.
- **Não foram criados** os DTOs da criação em lote de assentos nem da geração de ingressos para um jogo: eles dependem do desenho dos passos 3.4 e 3.5 e serão criados nessas fases.
- Entidades e DTOs foram testados fora do repositório (38 verificações: pagamentos, constantes, padrões, validações e conversões).
- [x] **6.14** Responsividade: manter o `viewport` e as *media queries* dos CSS (há pontos entre 480 px e 1400 px), testar em largura de celular.
- [x] **6.15** *Pronto quando:* o administrador cadastra um jogo e gera os ingressos, e um comprador navega da Home até uma compra completa pelo navegador, escolhendo jogo, setor e assento, com a mesma regra de negócio da Api.

**Notas da Fase 6 (decisões tomadas durante a execução):**

- **Autenticação da Web:** cookie com o `Perfil` como *claim* de papel. A cada requisição, o `OnValidatePrincipal` consulta o usuário no banco e derruba o cookie se a conta foi **desativada** ou se o **perfil mudou** (testado: conta desativada deixa de entrar na hora; quem é promovido a `ADMIN` precisa entrar de novo). Sem login social (premissa 4.8).
- **Carrinho na sessão** guarda só os ids dos ingressos; preço e disponibilidade são relidos do banco a cada tela (`CarrinhoMontador`). O formulário de pagamento só aceita o método (`[Bind("MetodoPagamento")]`): total e usuário vêm do servidor. Boleto continua recusado pelo Negócio (premissa de pagamento simulado). Sair da conta esvazia o carrinho.
- **Para a Web chegar aos ingressos escolhidos** foi acrescentado `IngressoNegocio.ListarPorIds` (usa o `ObterPorIds` que o repositório já tinha).
- **Um único CSS** (`wwwroot/css/mundial.css`) no lugar dos vários `.css` do modelo antigo, mais o Bootstrap da pasta `lib`. As bandeiras vêm da tabela `Bandeiras` (nome do time → arquivo `.svg`), sem coluna nova no banco; time desconhecido aparece sem bandeira. Os arquivos de imagem foram copiados; o `Claude Setup.exe` não.
- **Cultura:** a requisição usa a cultura invariante (decimais com ponto e datas ISO nos campos `number` e `datetime-local`); a **exibição** é em pt-BR pela classe `Formatacao`.
- **Área `Admin`** (`Areas/Admin`): controladores herdam de `AdminControllerBase` (`[Authorize(Roles = ADMIN)]`). Uma página por entidade (Estádios, Setores, Assentos, Jogos, Ingressos) com tabela, formulário na mesma página (`?editar=id`), `Salvar` e `Excluir` por POST; erros de regra aparecem na própria página. Assentos tem a seção "criar vários" e Ingressos tem "gerar para um jogo", "criar individual", alterar preço (só se `DISPONIVEL`), cancelar e excluir (nunca `VENDIDO`).
- **Todo POST tem token antifalsificação**; sem token a resposta é 400 (testado). Após o login, só volta para endereços do próprio site (`Url.IsLocalUrl`).
- **Verificação (6.15):** a Web foi iniciada de verdade e exercitada por HTTP (cookies e tokens reais) contra o banco real: em dois roteiros (comprador e administração); as falhas que apareceram foram defeitos dos próprios roteiros (texto HTML codificado, caminho convertido pelo Git Bash, conta de teste usando assento já vendido, contagem errada) e o do layout descrito abaixo, e no fim tudo passou. Cobriu páginas públicas, 302 para o login e 403/Acesso negado, cadastro e login com todas as falhas, **dois compradores disputando o mesmo assento** (o segundo é avisado e paga só o que sobrou), Pix aprovado e Boleto recusado, Meus ingressos com o QR, Minha conta (nome, e-mail repetido, senha, desativar) e o CRUD de cada página de administração, inclusive as recusas (setor acima da capacidade do estádio, assento repetido, lote acima da capacidade, excluir com dependentes, mexer em ingresso vendido). Tudo o que o roteiro criou foi desfeito (banco com 7/21/175/6/150 e nenhum usuário).
- **Responsividade (6.14):** capturas em 1366, 768 e 390 px, sem rolagem horizontal da página em nenhuma tela; as tabelas da administração rolam dentro do cartão no celular. Defeito encontrado e corrigido: em tela estreita o painel de administração era esticado pela tabela (a grade foi trocada por bloco abaixo de 1024 px).
- **Observações:** (1) os nomes de estádio **não são únicos** no banco; cadastrar o mesmo nome duas vezes é aceito. (2) Em desenvolvimento, o `MapStaticAssets` serve a versão compactada do CSS gerada na **compilação**; depois de mudar um arquivo de `wwwroot`, é preciso compilar de novo para ver a alteração no navegador. (3) Não há projeto de testes automatizados no repositório: os roteiros ficaram fora dele.

### Fase 7: fechamento e evidências do manual (Etapa 4)

- [ ] **7.1** Reescrever o `backend/README.md`: ele ainda descreve o `Cliente`, o banco por migrations e `NomeDoSistema`.
- [ ] **7.2** Reunir as evidências que o manual exige: captura da solution no Visual Studio mostrando os cinco projetos; diagrama da arquitetura (camadas, banco e app Flutter); trechos comentados de ao menos um repositório, uma classe de negócio, um controller MVC e um controller da API; trecho da chamada da stored procedure; e a descrição da POO aplicada.
- [ ] **7.3** Conferir as regras de dependência do manual: Web e Api não acessam o banco nem o Repositório diretamente; nenhuma regra em controller ou view; Modelos não referencia ninguém; connection string só no `appsettings.json`; consultas parametrizadas.
- [ ] **7.4** *Pronto quando:* a lista acima está atendida e o `git status` mostra só o que deve ser commitado.

### Fase 8: apoio ao app mobile

Feita depois da Fase 6, a pedido do grupo, para o app Flutter. O plano do app (`docs/Passo_a_passo_Mobile_PIM_IV.md`, Fase 1 e seção 4) traz o motivo de cada decisão.

- [x] **8.1** `IngressoCompradoDto` (`GET /api/vendas/meus-ingressos`) ganhou `TimeA`, `TimeB`, `EstadioNome` e `EstadioCidade`, os mesmos nomes do `JogoDto`. `Partida` continua, porque a Web usa.
- [x] **8.2** `POST /api/vendas/validar`, só `ADMIN`: recebe o `CodigoQR`, confere as regras e marca o ingresso como utilizado. Caminho: `VendasController`, `VendaNegocio.ValidarIngresso` e `VendaRepositorio`, com os DTOs `IngressoValidarDto` e `IngressoValidadoDto`. Recusas viram 400 com `{ "erro": "..." }`, pelo `RegraDeNegocioFiltro`.
- [x] **8.3** `05_Dados_Teste.sql`: jogos de 14 a 19/12/2026, com um `UPDATE` que acerta as datas em um banco já povoado.
- [x] **8.4** `MundialTickets.Api.http`: seção nova com as chamadas da Portaria.

**Notas da Fase 8 (decisões tomadas durante a execução):**

- **Ordem das conferências:** o código existe, o ingresso está `VENDIDO`, ainda não foi utilizado e o jogo não começou. Só então o ingresso é marcado.
- **A validade vem de `Jogo.DataHora`, e não de `QRCode.DataExpiracao`.** A trigger copia a data do jogo para `DataExpiracao` no momento da venda, e o `JogoNegocio.Atualizar` não mexe nessa cópia. Com a data atual do jogo, uma mudança de data vale na hora, sem sincronizar nada. A coluna e o campo do DTO continuam existindo.
- **Primeira gravação em `QRCode` pelo EF.** A regra "só a procedure e as triggers gravam" passa a ter uma exceção: o campo `Utilizado`, marcado por `ExecuteUpdate`. A tabela `QRCode` não tem trigger, então não precisa de `HasTrigger`.
- **Dois leitores ao mesmo tempo:** o `UPDATE` único leva a condição `Utilizado = 0`. O segundo leitor espera o primeiro, altera zero linhas e recebe "Este ingresso já foi utilizado.". A leitura anterior é sem rastreamento, porque o `ExecuteUpdate` não atualiza objetos já carregados (o mesmo cuidado das notas da Fase 2).
- **Limites aceitos:** não há tolerância depois do início do jogo, e a validação aceita qualquer jogo futuro, porque não sabe qual jogo está acontecendo. Por isso a resposta traz `DataJogo`, para quem está na portaria conferir o dia. O banco não guarda a hora da validação.
- **Nenhum registro novo na injeção de dependência:** a rota usa o `VendaNegocio`, e o `VendaRepositorio` continua sendo a única classe que fala com `QRCode`. Os dois blocos do `Program.cs` não mudaram.
- **Seed:** o `INSERT` de `Jogo` ignora jogos que já existem, e por isso o script ganhou um `UPDATE`. Repetir o script devolve os 6 jogos às datas do arquivo, o que desfaz uma mudança de data feita pelo administrador neles. Pelo `sqlcmd`, use a opção `-I`: sem ela, o `INSERT` em `Ingresso` falha com o erro 1934 (`QUOTED_IDENTIFIER`), sem gravar nada. O SSMS já usa esse padrão.
- **Verificação:** a Api e a Web foram iniciadas e exercitadas por HTTP contra o banco real, em 28 conferências. Cobriram sem token (401), token de `CLIENTE` (403), código inexistente, código em branco, código válido, código repetido, status alterado, jogo no passado, `DataExpiracao` no passado com o jogo no futuro (200), três rodadas de dois leitores simultâneos (sempre um 200 e um 400), a Web com os selos certos, o OpenAPI com o cadeado e o Scalar. Duas falhas foram do próprio roteiro (acentos codificados no HTML e o Scalar devolvendo HTML) e foram reconferidas. O comprador temporário do teste foi apagado.

---

## 6. Ordem de commits sugerida

Um commit por fase concluída (Fases 0 a 8), com mensagens no padrão do histórico (`Add: ...`), para que cada etapa possa ser revertida sozinha. A coluna `Perfil` nos scripts `01` e `02` pode ir em um commit próprio, antes da Fase 1.

## 7. Riscos já identificados

- A trigger `trg_ItemVenda_UpdateValorTotal` tinha o limite de `TOP 1 VendaID` (só recalculava a primeira venda de um INSERT com itens de vendas diferentes). Foi corrigida no banco (commits do Caique de 30 e 31/10) e testada: o INSERT com duas vendas recalcula as duas. O risco deixou de existir.
- A procedure grava `APROVADO` sem consultar o método de pagamento. O plano contorna isso decidindo no Negócio, sem alterar o banco.
- Dois compradores escolhendo o mesmo assento ao mesmo tempo: o banco protege (UNIQUE e trigger), mas sem reserva (premissa 4.6) o segundo só descobre ao pagar. A tradução da `SqlException` (passo 2.9) garante uma mensagem clara.
- O login da Api não limita tentativas: alguém pode tentar muitas senhas seguidas contra um e-mail. Aceitável no trabalho acadêmico; em produção entrariam bloqueio temporário ou limite de requisições.
- A chave do JWT está no `appsettings.json` do repositório (ver as notas da Fase 5).
- O `Perfil` é gravado na tabela e promovido por `UPDATE` manual (premissa 4.4): quem tem acesso ao banco pode se tornar `ADMIN`. É aceitável para o contexto acadêmico.
- Com uma página por entidade a administração fica com 5 telas, mas o desenho (tabela, formulário e exclusão na mesma página) é código novo, e não cópia do Cliente do template. Se o tempo apertar, a ordem de corte sugerida é: Assento, Ingresso, Setor, Jogo e, por último, Estádio.
