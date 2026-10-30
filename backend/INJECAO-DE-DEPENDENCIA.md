# Injeção de dependência — o que é e como usar no PIM

O manual do PIM IV exige: *"as dependências entre as camadas devem ser
configuradas por injeção de dependência no arquivo Program.cs dos projetos Web
e Api"*. Este guia explica o que isso quer dizer, partindo do que você já sabe
de POO, e mostra exatamente o que escrever quando criar uma entidade nova.

## 1. O que você já sabe: uma classe que precisa de outra

Em POO você já viu composição: uma classe que *tem* outra como campo. No PIM,
cada camada precisa da camada de baixo para trabalhar:

- o `ClientesController` precisa de um `ClienteNegocio` para aplicar as regras;
- o `ClienteNegocio` precisa de um `ClienteRepositorio` para ler e gravar;
- o `ClienteRepositorio` precisa de um `AppDbContext` para falar com o banco;
- o `AppDbContext` precisa da connection string para saber qual banco abrir.

Cada uma dessas classes recebe a outra **no construtor**. Abra
`MundialTickets.Negocio\ClienteNegocio.cs` e veja:

```csharp
public ClienteNegocio(IClienteRepositorio repositorio)
{
    _repositorio = repositorio;
}
```

Isso você já conhece: um construtor com parâmetro, que guarda o valor num campo.
A pergunta é: **quem chama esse construtor, e de onde vem o repositório?**

## 2. O jeito sem injeção de dependência (e por que não serve)

Sem injeção de dependência, cada controller teria de montar a cadeia inteira
na mão, com `new`, de baixo para cima:

```csharp
// NÃO FAÇA ASSIM — é só para entender o problema
public IActionResult Index()
{
    var opcoes = new DbContextOptionsBuilder<AppDbContext>()
        .UseSqlServer("Server=localhost;Database=MundialTickets;Trusted_Connection=True;TrustServerCertificate=True")
        .Options;
    var contexto    = new AppDbContext(opcoes);
    var repositorio = new ClienteRepositorio(contexto);
    var negocio     = new ClienteNegocio(repositorio);

    var clientes = negocio.Listar();
    ...
}
```

Isso funciona, mas cria três problemas:

1. **A connection string se espalha pelo código.** Ela apareceria em todo
   controller, de toda entidade, nos dois projetos. O manual proíbe: ela tem de
   ficar no `appsettings.json`. E no dia em que o servidor mudar de nome, você
   teria de caçar todas as cópias.
2. **A Web e a Api passam a mexer no Repositório.** O controller estaria
   criando um `ClienteRepositorio` e um `AppDbContext`, o que quebra a regra do
   manual: *"os projetos Web e Api não devem acessar o banco de dados nem a
   camada de Repositório diretamente"*.
3. **Ninguém fecha a conexão com o banco.** O contexto foi criado e nunca é
   descartado. Com muitos acessos, as conexões se acumulam até o SQL Server
   recusar novas.

## 3. A ideia: pedir em vez de criar

A injeção de dependência inverte quem faz o trabalho. Em vez de cada classe
**criar** o que precisa, ela só **pede** no construtor. Quem cria e entrega é o
ASP.NET Core, seguindo uma lista que você escreve **uma única vez** no
`Program.cs`.

Pense numa lanchonete. O atendente anota "um X-burguer" e não vai até a
cozinha fritar o hambúrguer. A cozinha tem a receita: um X-burguer leva pão,
hambúrguer e queijo; o hambúrguer leva carne e tempero. O atendente só pede, e
o lanche chega montado. No PIM, o controller é o atendente, o `Program.cs` é o
livro de receitas, e o ASP.NET Core é a cozinha.

O controller fica assim, sem nenhum `new`:

```csharp
public class ClientesController : Controller
{
    private readonly ClienteNegocio _negocio;

    public ClientesController(ClienteNegocio negocio)   // só pede
    {
        _negocio = negocio;
    }

    public IActionResult Index()
    {
        var clientes = _negocio.Listar();                // e usa
        ...
    }
}
```

## 4. A lista de montagem, linha por linha

No `Program.cs` da Web e no da Api existe este bloco (igual nos dois):

```csharp
builder.Services.AddDbContext<AppDbContext>(opcoes => opcoes.UseSqlServer(connectionString));
builder.Services.AddScoped<IClienteRepositorio, ClienteRepositorio>();
builder.Services.AddScoped<ClienteNegocio>();
```

Leia cada linha como uma frase:

| Linha | Em português |
|---|---|
| `AddDbContext<AppDbContext>(... UseSqlServer(connectionString))` | Quando alguém pedir um `AppDbContext`, crie um que use SQL Server com a connection string do `appsettings.json`. |
| `AddScoped<IClienteRepositorio, ClienteRepositorio>()` | Quando alguém pedir um `IClienteRepositorio` (a interface), entregue um `ClienteRepositorio` (a classe que implementa a interface). |
| `AddScoped<ClienteNegocio>()` | Quando alguém pedir um `ClienteNegocio`, crie um. |

A segunda linha é polimorfismo, que você já viu em POO: o `ClienteNegocio`
declara que precisa de *algo que cumpra o contrato* `IClienteRepositorio`, e o
`Program.cs` decide qual classe concreta cumpre esse contrato. Se um dia o
grupo trocar o Entity Framework por Dapper, escreve outra classe que implementa
a mesma interface e muda só esta linha; o `ClienteNegocio` nem fica sabendo.

**Por que dois `Program.cs`?** Porque a Web e a Api são dois programas
separados: cada um sobe sozinho e tem a sua própria lista de montagem. Por isso
o bloco é igual nos dois, e toda linha nova vai para os dois.

**O que é `AddScoped`?** Diz *quanto tempo* o objeto vive. *Scoped* significa
um objeto novo para cada requisição (cada clique na Web, cada chamada da Api),
jogado fora quando a resposta sai. O `AddDbContext` funciona do mesmo jeito, e
é ao jogar o contexto fora que a conexão com o banco é fechada — o problema 3
da seção 2 se resolve sozinho. Existem também `AddSingleton` (um objeto só para
o sistema inteiro) e `AddTransient` (um novo a cada pedido), mas no PIM use
sempre `AddScoped` para repositórios e classes de negócio.

## 5. O que acontece quando o usuário abre a tela de clientes

1. O navegador pede `/Clientes`.
2. O ASP.NET Core vê que precisa criar um `ClientesController` e olha o
   construtor dele: ele pede um `ClienteNegocio`.
3. Procura `ClienteNegocio` na lista do `Program.cs`. Acha. Olha o construtor:
   ele pede um `IClienteRepositorio`.
4. Procura `IClienteRepositorio` na lista. A lista diz: entregue um
   `ClienteRepositorio`. Olha o construtor dele: pede um `AppDbContext`.
5. Procura `AppDbContext`. A lista diz como criar, com a connection string.
6. Agora monta de baixo para cima: contexto → repositório → negócio →
   controller. E chama `Index()`.
7. A resposta sai, e tudo o que foi criado para esta requisição é descartado.

Você não escreve nada disso. Escreve só os construtores e as linhas do
`Program.cs`.

## 6. Receita: criando a entidade `Ingresso`

Sempre que criar uma entidade nova, os construtores seguem o mesmo molde do
Cliente:

```csharp
// MundialTickets.Repositorio\IngressoRepositorio.cs
public class IngressoRepositorio : IIngressoRepositorio
{
    private readonly AppDbContext _contexto;

    public IngressoRepositorio(AppDbContext contexto)        // pede o banco
    {
        _contexto = contexto;
    }
    ...
}

// MundialTickets.Negocio\IngressoNegocio.cs
public class IngressoNegocio
{
    private readonly IIngressoRepositorio _repositorio;

    public IngressoNegocio(IIngressoRepositorio repositorio)  // pede o repositório
    {
        _repositorio = repositorio;
    }
    ...
}

// MundialTickets.Web\Controllers\IngressosController.cs  (e o mesmo na Api)
public class IngressosController : Controller
{
    private readonly IngressoNegocio _negocio;

    public IngressosController(IngressoNegocio negocio)      // pede o negócio
    {
        _negocio = negocio;
    }
    ...
}
```

E acrescente **duas linhas em cada `Program.cs`** (o da Web e o da Api), logo
abaixo das do Cliente:

```csharp
builder.Services.AddScoped<IIngressoRepositorio, IngressoRepositorio>();
builder.Services.AddScoped<IngressoNegocio>();
```

O `AddDbContext` não se repete: o mesmo `AppDbContext` serve a todas as
entidades. O que muda nele é ganhar o `DbSet<Ingresso>`.

Se o negócio de Ingresso precisar consultar clientes (por exemplo, para saber
se o comprador está ativo), é só pedir os dois no construtor:

```csharp
public IngressoNegocio(IIngressoRepositorio repositorio, IClienteRepositorio clientes)
```

Como os dois já estão na lista, o ASP.NET entrega os dois.

## 7. Os erros que você vai ver

As mensagens abaixo são as reais, copiadas do sistema rodando.

**Esqueceu de registrar a classe de negócio** (a linha `AddScoped<IngressoNegocio>()`).
O sistema sobe, mas a tela ou o endpoint devolve erro 500 com:

```
InvalidOperationException: Unable to resolve service for type
'MundialTickets.Negocio.ClienteNegocio' while attempting to activate
'MundialTickets.Api.Controllers.ClientesController'.
```

Leia assim: *"não consegui criar o ClientesController, porque ele pediu um
ClienteNegocio e ninguém me ensinou a criar um"*. Correção: a linha que falta
no `Program.cs` — e confira se ela está nos **dois**.

**Esqueceu de registrar o repositório** (a linha
`AddScoped<IIngressoRepositorio, IngressoRepositorio>()`). Aqui o sistema nem
chega a subir: o `dotnet run` ou o F5 para na hora com:

```
System.AggregateException: Some services are not able to be constructed
(... Unable to resolve service for type 'MundialTickets.Repositorio.Interfaces.IClienteRepositorio'
while attempting to activate 'MundialTickets.Negocio.ClienteNegocio'.)
```

O ASP.NET confere a lista ao iniciar e percebe que o negócio pede algo que não
está nela. Correção: a linha do repositório nos dois `Program.cs`.

**Escreveu `new ClienteNegocio()` no controller.** Não compila: o construtor
exige um repositório. E se você tentar resolver criando o repositório também,
volta ao problema da seção 2. Peça no construtor do controller.

**Registrou a classe no lugar da interface** (`AddScoped<ClienteRepositorio>()`,
sem a interface). O `ClienteNegocio` pede `IClienteRepositorio`, que não está
na lista, e dá o mesmo erro do repositório esquecido. A linha precisa dizer as
duas coisas: `AddScoped<IClienteRepositorio, ClienteRepositorio>()`.

## 8. Resumo para colar no caderno

- Toda classe **pede** o que precisa no construtor e **nunca** dá `new` em
  controller, negócio, repositório ou contexto.
- O `Program.cs` é a lista de montagem. Cada entidade nova = **duas linhas**
  (repositório e negócio), nos **dois** `Program.cs`.
- Interface no repositório: a linha diz `<Interface, Classe>`.
- Erro com *Unable to resolve service for type 'X'* = falta registrar `X` no
  `Program.cs`.
