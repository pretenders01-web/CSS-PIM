# MundialTickets — estrutura base do PIM IV

Esta é a solution pronta na organização que o **Manual do PIM IV (Etapa 4)** exige:
cinco projetos, as referências no sentido certo, Entity Framework Core e Dapper
instalados, e um exemplo completo de **Cliente** atravessando todas as camadas.
O grupo troca o nome, apaga o que não precisar e cria as próprias entidades
seguindo o mesmo molde.

## O que já vem pronto

```
MundialTickets.sln
│
├── MundialTickets.Modelos       Biblioteca de classes
│   ├── Cliente.cs                 entidade com validações básicas
│   └── Dtos/
│       ├── ClienteDto.cs          o que o sistema mostra (telas da Web e JSON da Api)
│       └── ClienteSalvarDto.cs    o que o usuário preenche (formulários e POST/PUT)
│
├── MundialTickets.Repositorio   Biblioteca de classes (EF Core + Dapper)
│   ├── Contexto/AppDbContext.cs   DbContext, mapeamento e HasTrigger
│   ├── Interfaces/IClienteRepositorio.cs
│   ├── ClienteRepositorio.cs      cadastro com EF Core, procedure com Dapper
│   └── Migrations/                cria a tabela, a trigger e a procedure
│
├── MundialTickets.Negocio       Biblioteca de classes
│   ├── ClienteNegocio.cs          regras: CPF com 11 dígitos, e-mail e CPF únicos
│   └── RegraDeNegocioException.cs
│
├── MundialTickets.Web           ASP.NET Core MVC (Razor)
│   ├── Program.cs                 injeção de dependência (igual à da Api)
│   ├── Controllers/ClientesController.cs
│   └── Views/Clientes/            Index, Criar, Editar, Excluir e a partial _Formulario
│
└── MundialTickets.Api           ASP.NET Core Web API (para o app Flutter)
    ├── Program.cs                 injeção de dependência, OpenAPI e Scalar
    └── Controllers/ClientesController.cs
```

Os DTOs ficam no Modelos porque Web e Api usam os mesmos: a tela de cadastro e o
POST da Api recebem o mesmo `ClienteSalvarDto`, com as mesmas validações e as
mesmas mensagens de erro. A entidade `Cliente` nunca sai para a tela nem para o
app; o que sai é sempre o DTO.

Sentido das referências, como o manual manda:

```
Web ──┐
      ├──► Negocio ──► Repositorio ──► Modelos
Api ──┘
```

Os controllers da Web e da Api recebem **só** o `ClienteNegocio`; nenhum deles
toca no repositório nem no banco. Quem entrega o `ClienteNegocio` pronto ao
controller é a **injeção de dependência**, configurada num bloco de três linhas
no `Program.cs` da Web e da Api, como o manual exige. Se você nunca viu isso,
leia o [INJECAO-DE-DEPENDENCIA.md](INJECAO-DE-DEPENDENCIA.md) antes de criar a
sua primeira entidade: ele explica do zero, com a receita e os erros mais comuns.

Pacotes instalados: `Microsoft.EntityFrameworkCore.SqlServer` e `Dapper` no
Repositorio; `Microsoft.EntityFrameworkCore.Design` na Web e na Api (é o que o
comando `dotnet ef` precisa); `Microsoft.EntityFrameworkCore.Tools` na Api (é o
que faz o `Update-Database` funcionar no Visual Studio); `Microsoft.AspNetCore.OpenApi`
na Api (gera a documentação OpenAPI); `Scalar.AspNetCore` na Api (a tela gráfica
para ver e testar os endpoints).

O projeto é de .NET 9, por compatibilidade com as máquinas do laboratório, e
roda em máquina com **.NET 9 ou .NET 10**: a Web e a Api têm a opção
`RollForward` no `.csproj`, que faz o sistema usar o .NET 10 quando o 9 não
estiver instalado. Não é preciso mudar nada no projeto.

## Como rodar pela primeira vez

### 0. Apontar para o seu SQL Server

O sistema usa **SQL Server**. A connection string fica no `appsettings.json` da
Web **e** no da Api (chave `Padrao`), e vem assim:

```json
"Padrao": "Server=localhost;Database=MundialTickets;Trusted_Connection=True;TrustServerCertificate=True"
```

Antes de tudo, confira se o `Server=` bate com o SQL Server da sua máquina.
Existem dois casos comuns, e você descobre qual é o seu de um destes jeitos:

- **Pelo SSMS** (SQL Server Management Studio): ao abrir, a janela *Conectar ao
  Servidor* mostra o campo *Nome do servidor*. É esse nome que vai no `Server=`.
- **Pelos serviços do Windows**: tecle **Win+R**, digite `services.msc` e
  procure os serviços que começam com *SQL Server (...)*. O que está entre
  parênteses é o nome da instância.

| O serviço se chama | É a instância | No `appsettings.json` escreva |
|---|---|---|
| SQL Server (MSSQLSERVER) | padrão | `Server=localhost;` (já vem assim) |
| SQL Server (SQLEXPRESS) | Express | `Server=localhost\\SQLEXPRESS;` |

Repare na **barra dupla** no caso do Express: dentro de um arquivo JSON, a barra
invertida precisa ser escrita duas vezes. No SSMS o nome aparece com uma barra
só (`localhost\SQLEXPRESS`); no JSON, com duas.

O que cada parte da connection string faz:

- `Server=localhost` diz em qual SQL Server conectar.
- `Database=MundialTickets` é o nome do banco que será criado. Pode trocar pelo
  nome do sistema do grupo.
- `Trusted_Connection=True` entra no SQL Server com o seu usuário do Windows,
  sem senha — o mesmo jeito que o SSMS entra com *Autenticação do Windows*. Se
  na sua máquina você entra no SSMS com usuário e senha do SQL Server (como
  `sa`), troque essa parte por `User Id=sa;Password=sua_senha`.
- `TrustServerCertificate=True` aceita o certificado de segurança que o SQL
  Server instalado na sua máquina gera sozinho. Sem isso, a conexão é recusada
  com o erro *"A cadeia de certificação foi emitida por uma autoridade que não
  é de confiança"*. Em máquina de desenvolvimento, mantenha.

Mudou o `Server=`? Mude nos **dois** `appsettings.json` (Web e Api).

### 1. Criar o banco

O banco nasce da migration, que cria o banco `MundialTickets`, a tabela
`Clientes`, a trigger `TR_Clientes_DataAtualizacao` e a procedure
`sp_Clientes_BuscarPorNome`. Você não precisa criar nada no SSMS antes.

**Pelo terminal**, na pasta onde está o `.sln`:

```bash
dotnet tool install --global dotnet-ef
```

```bash
dotnet ef database update --project MundialTickets.Repositorio --startup-project MundialTickets.Api
```

O primeiro comando só é necessário uma vez por máquina. Se ele disser que a
ferramenta já está instalada, siga para o segundo. No fim, o segundo escreve
`Done.`

**Pelo Visual Studio**: clique com o botão direito em `MundialTickets.Api` no
Gerenciador de Soluções e escolha *Definir como Projeto de Inicialização*. Abra
o menu *Ferramentas › Gerenciador de Pacotes do NuGet › Console do Gerenciador
de Pacotes*. Na caixa *Projeto padrão*, no alto do console, escolha
`MundialTickets.Repositorio`. Depois digite no console:

```
Update-Database
```

Para conferir, abra o SSMS, conecte no seu servidor e expanda *Bancos de
Dados*: o banco `MundialTickets` aparece ali (se não aparecer, clique com o
botão direito em *Bancos de Dados* › *Atualizar*). Dentro dele, a tabela fica
em *Tabelas*, a procedure em *Programação › Procedimentos Armazenados* e a
trigger em *Tabelas › dbo.Clientes › Gatilhos*.

### Como o sistema chega ao banco

A conexão passa por quatro pontos, sempre nesta ordem. Saber o caminho ajuda a
achar o problema quando a conexão falha.

1. **`appsettings.json`** (da Web e da Api) guarda a connection string, na
   chave `Padrao`. É o único lugar onde ela está escrita.
2. **`Program.cs`** lê essa chave com
   `builder.Configuration.GetConnectionString("Padrao")` e entrega ao Entity
   Framework na linha `AddDbContext<AppDbContext>(opcoes => opcoes.UseSqlServer(connectionString))`.
   Se a chave não existir, o sistema para logo ao subir com a mensagem
   *Connection string 'Padrao' não encontrada no appsettings.json*.
3. **`AppDbContext`** (no Repositorio) recebe essa configuração pronta no
   construtor. É ele que abre e fecha a conexão com o SQL Server.
4. **`ClienteRepositorio`** recebe o `AppDbContext` no construtor e o usa de
   dois jeitos: pelo Entity Framework (`_contexto.Clientes...`) no cadastro, e
   pelo Dapper na procedure, pegando a mesma conexão com
   `_contexto.Database.GetDbConnection()`. Assim o Dapper não precisa de uma
   connection string própria.

Nenhuma outra classe sabe que o banco existe. Os passos 2 a 4 são a injeção de
dependência funcionando — o [INJECAO-DE-DEPENDENCIA.md](INJECAO-DE-DEPENDENCIA.md)
explica esse mecanismo em detalhe.

### 2. Rodar a Api

**Pelo terminal**:

```bash
dotnet run --project MundialTickets.Api
```

Abra `http://localhost:5218/scalar` no navegador: aparece a tela do **Scalar**,
com todos os endpoints da API (veja "Como testar pela tela", mais abaixo).

**Pelo Visual Studio**: botão direito em `MundialTickets.Api` › *Definir como
Projeto de Inicialização* e **F5**. O navegador abre sozinho no Scalar, no
endereço `https` (`https://localhost:7077/scalar`); na primeira vez o Visual
Studio pede para confiar no certificado de desenvolvimento — aceite.

### 3. Rodar a Web

**Pelo terminal**, em outra janela:

```bash
dotnet run --project MundialTickets.Web
```

Abra `http://localhost:5157/Clientes`.

**Pelo Visual Studio**: botão direito na solution › *Configurar Projetos de
Inicialização* › *Vários projetos de inicialização*, marque *Iniciar* em
`MundialTickets.Web` e em `MundialTickets.Api`, e **F5**. Assim os dois sobem
juntos, cada um no seu navegador. A Web abre em `https://localhost:7241`;
clique em *Clientes* no menu.

## Endpoints da Api

| Verbo | Endereço | O que faz | Resposta |
|---|---|---|---|
| GET | `/api/clientes` | lista todos | 200 |
| GET | `/api/clientes/1` | um cliente | 200 ou 404 |
| GET | `/api/clientes/buscar?nome=ana` | busca pela **stored procedure** | 200 |
| POST | `/api/clientes` | cadastra | 201 com cabeçalho `Location`, ou 400 |
| PUT | `/api/clientes/1` | altera | 204, 400 ou 404 |
| DELETE | `/api/clientes/1` | exclui | 204 ou 404 |

Corpo do POST e do PUT:

```json
{ "nome": "Ana Souza", "email": "ana@exemplo.com", "cpf": "123.456.789-09", "ativo": true }
```

### Como testar pela tela: o Scalar

Com a Api rodando, abra `/scalar` (o F5 do Visual Studio já abre). A tela tem,
à esquerda, a lista dos endpoints agrupados em *Clientes*, cada um com o verbo
colorido (GET, POST, PUT, DEL). Para testar um deles:

1. Clique no endpoint na lista da esquerda. O centro da tela mostra o que ele
   recebe e o que devolve.
2. Clique em **Test Request**. Abre uma janela com o endereço já preenchido.
3. Se o endpoint recebe dados (POST e PUT), preencha o JSON em *Body*. Se tem
   `{id}` no endereço, preencha o id em *Path Parameters*.
4. Clique em **Send**. A resposta aparece embaixo, com o código HTTP (201, 400,
   404...) e o JSON que a API devolveu.

O Scalar não é quem documenta a API: ele só **lê** o documento OpenAPI
(`/openapi/v1.json`, explicado mais abaixo) e desenha a tela a partir dele. Por
isso, todo endpoint novo que o grupo criar aparece ali sozinho, sem configurar
nada.

### Como testar pelo editor: o arquivo `MundialTickets.Api.http`

Para repetir os mesmos testes várias vezes, há também o arquivo
`MundialTickets.Api.http`, que já vem com todas as chamadas acima, na ordem
certa (cadastrar, listar, alterar, buscar, excluir) e com a resposta esperada
escrita em cima de cada uma. Com a Api rodando:

- **No Visual Studio**: abra o arquivo no Gerenciador de Soluções. Em cima de
  cada chamada aparece *Enviar solicitação*; clique, e a resposta abre num
  painel ao lado, com o código HTTP e o JSON.
- **No VS Code**: instale a extensão *REST Client* (de Huachao Mao) pela aba
  de extensões (**Ctrl+Shift+X**). Depois abra o arquivo: em cima de cada
  chamada aparece *Send Request*.

O arquivo usa o endereço `http://localhost:5218`, que funciona tanto com
`dotnet run` quanto com o F5 do Visual Studio.

### Para que serve o documento OpenAPI

O `/openapi/v1.json` é a descrição padronizada da API: lista cada endpoint,
o verbo, o que ele recebe e o que devolve. Ele é útil em dois momentos do PIM:
para a parte do grupo que faz o aplicativo Flutter saber exatamente o que a
API oferece, e para a documentação dos endpoints que o manual recomenda na
Etapa 4 ("documentação dos endpoints com Swagger/OpenAPI").
Como é um formato padrão, ferramentas como o Postman importam esse arquivo e
montam todas as chamadas sozinhas.

## Trocar o nome do sistema

Como no manual, a estrutura vem com o nome `MundialTickets`, e cada grupo troca
pelo nome do próprio sistema. Faça isso **antes** de escrever qualquer código,
porque depois fica muito mais trabalhoso:

1. Feche o Visual Studio.
2. Renomeie as cinco pastas e os cinco `.csproj` (`MundialTickets.Web` →
   `CopaTickets.Web`, e assim por diante) e o `.sln`.
3. Troque o texto `MundialTickets` pelo novo nome em **todos** os arquivos da
   pasta, inclusive o `.sln`, os `.csproj` e os dois `appsettings.json`:
   - **no VS Code**: abra a pasta, menu *Editar › Substituir nos arquivos*
     (**Ctrl+Shift+H**), preencha os dois campos e clique em *Substituir tudo*;
   - **no Visual Studio**: abra só a pasta (*Arquivo › Abrir › Pasta*), menu
     *Editar › Localizar e Substituir › Substituir nos Arquivos*
     (**Ctrl+Shift+H**), em *Examinar* escolha a pasta e clique em
     *Substituir Tudo*.
4. Apague as pastas `bin` e `obj` de cada projeto, se existirem, e compile
   (`dotnet build` no terminal ou **Ctrl+Shift+B** no Visual Studio).
5. Como o `Database=` do `appsettings.json` também mudou, o banco antigo fica
   para trás: rode de novo o `database update` (seção 1) para criar o banco com
   o nome novo.

## Como criar a próxima entidade

Para cada entidade nova (Evento, Ingresso, Pedido...), repita o caminho do
Cliente, sempre de baixo para cima:

1. **Modelos**: a classe da entidade e os DTOs dela, na pasta Dtos.
2. **Repositorio**: o `DbSet` no `AppDbContext`, a interface e a classe do
   repositório.
3. **Negocio**: a classe com as regras.
4. **Program.cs da Web e da Api**: duas linhas em cada um, uma para o
   repositório e uma para o negócio (o exemplo comentado já está lá). A
   receita completa, com o código dos construtores, está na seção 6 do
   [INJECAO-DE-DEPENDENCIA.md](INJECAO-DE-DEPENDENCIA.md).
5. **Web**: controller e views, usando os DTOs.
6. **Api**: controller, usando os mesmos DTOs.
7. Gere a migration e atualize o banco:

```bash
dotnet ef migrations add NomeDaMudanca --project MundialTickets.Repositorio --startup-project MundialTickets.Api
dotnet ef database update --project MundialTickets.Repositorio --startup-project MundialTickets.Api
```

No Console do Gerenciador de Pacotes do Visual Studio, os mesmos dois passos
são `Add-Migration NomeDaMudanca` e `Update-Database`.

## Três cuidados que o manual cobra

- **Tabela com trigger precisa de `HasTrigger` no mapeamento.** Sem ele, todo
  INSERT e UPDATE nessa tabela dá erro no EF Core. Veja o exemplo no
  `AppDbContext`.
- **Trigger e procedure não são gerados pelo EF.** Escreva o SQL à mão dentro
  da migration com `migrationBuilder.Sql(...)`, como na migration `Inicial`.
  Para ter o script SQL completo do banco (útil no documento da Etapa 3), rode
  `dotnet ef migrations script --project MundialTickets.Repositorio --startup-project MundialTickets.Api -o banco.sql`.
- **Consulta sempre parametrizada.** No Dapper, os valores vão num objeto
  separado (`new { Trecho = trecho }`), nunca concatenados na string do SQL.
  É isso que impede SQL Injection.

## Se algo deu errado

As mensagens abaixo são as reais, copiadas do sistema rodando. Elas costumam
vir no meio de um texto longo em inglês; procure a frase da primeira coluna.

| Aparece | Causa | Correção |
|---|---|---|
| `error: 26 - Error Locating Server/Instance Specified` | O `Server=` do `appsettings.json` não é o nome do seu SQL Server. | Descubra o nome certo (seção 0) e corrija nos **dois** `appsettings.json`. |
| `A cadeia de certificação foi emitida por uma autoridade que não é de confiança` | Falta `TrustServerCertificate=True` na connection string. | Acrescente no fim da connection string, nos dois arquivos. |
| `Cannot open database "MundialTickets" requested by the login. The login failed.` | O banco ainda não foi criado. | Rode o `dotnet ef database update` ou o `Update-Database` (seção 1). |
| `Invalid column name 'Observacao'` | Você acrescentou uma propriedade na entidade, mas não gerou a migration, e a coluna não existe no banco. | Gere uma migration e atualize o banco (passo 7 de "Como criar a próxima entidade"). |
| `The model for context 'AppDbContext' has pending changes. Add a new migration before updating the database.` | Mesmo caso acima, visto pelo `database update`: a entidade mudou e não existe migration para a mudança. | `dotnet ef migrations add NomeDaMudanca ...` e depois o `database update`. |
| `Unable to resolve service for type 'MundialTickets.Negocio.ClienteNegocio' while attempting to activate '...ClientesController'` | A classe de negócio não foi registrada no `Program.cs`. | Acrescente o `AddScoped` dela nos **dois** `Program.cs` (ver [INJECAO-DE-DEPENDENCIA.md](INJECAO-DE-DEPENDENCIA.md), seção 7). |
| `Some services are not able to be constructed` e o sistema nem sobe | Um repositório não foi registrado no `Program.cs`. | Acrescente o `AddScoped<IInterface, Classe>` dele nos dois `Program.cs`. |
| Erro de compilação dizendo que um arquivo está em uso por outro processo (`MundialTickets.Web` ou `MundialTickets.Api`) | O sistema ainda está rodando e segura os arquivos. | Pare a execução (**Shift+F5** no Visual Studio, **Ctrl+C** no terminal) e compile de novo. |
