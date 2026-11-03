using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MundialTickets.Api.Filtros;
using MundialTickets.Api.Seguranca;
using MundialTickets.Modelos.Pagamentos;
using MundialTickets.Negocio;
using MundialTickets.Repositorio;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// A connection string vem do appsettings.json — nunca do código-fonte.
var connectionString = builder.Configuration.GetConnectionString("Padrao")
    ?? throw new InvalidOperationException("Connection string 'Padrao' não encontrada no appsettings.json.");

// ---------- Injeção de dependência ----------
// Esta é a LISTA DE MONTAGEM do sistema. Cada linha ensina o ASP.NET Core a
// criar uma peça. Depois, quando um controller pede um EstadioNegocio no
// construtor, o ASP.NET monta a cadeia inteira sozinho:
//
//   EstadiosController  pede  EstadioNegocio
//   EstadioNegocio      pede  IEstadioRepositorio  -> recebe um EstadioRepositorio
//   EstadioRepositorio  pede  AppDbContext         -> recebe com a connection string
//
// Ninguém escreve "new" para essas classes. Explicação passo a passo, com os
// erros mais comuns: INJECAO-DE-DEPENDENCIA.md, na pasta da solution.
//
// ATENÇÃO: este bloco é IGUAL no Program.cs da Web. Mudou aqui, mude lá também.

// 1) O banco: "quando alguém pedir um AppDbContext, crie um usando SQL Server
//    e esta connection string".
builder.Services.AddDbContext<AppDbContext>(opcoes => opcoes.UseSqlServer(connectionString));

// 2) Os repositórios: "quando alguém pedir uma interface (por exemplo, IEstadioRepositorio),
//    entregue a classe dela (EstadioRepositorio)". Um par de linhas por assunto.
builder.Services.AddScoped<IEstadioRepositorio, EstadioRepositorio>();
builder.Services.AddScoped<ISetorRepositorio, SetorRepositorio>();
builder.Services.AddScoped<IAssentoRepositorio, AssentoRepositorio>();
builder.Services.AddScoped<IJogoRepositorio, JogoRepositorio>();
builder.Services.AddScoped<IIngressoRepositorio, IngressoRepositorio>();
builder.Services.AddScoped<IUsuarioRepositorio, UsuarioRepositorio>();
builder.Services.AddScoped<IVendaRepositorio, VendaRepositorio>();

// 3) Serviços de apoio SEM ESTADO (não guardam nada entre uma chamada e outra), por isso
//    AddSingleton: uma única instância serve o sistema inteiro.
//    - IHashDeSenha: gera e confere o hash das senhas.
//    - IMetodoPagamento: as três formas de pagamento. Registrar várias classes para o mesmo
//      contrato faz o VendaNegocio, que pede um IEnumerable<IMetodoPagamento>, receber as três.
builder.Services.AddSingleton<IHashDeSenha, HashDeSenha>();
builder.Services.AddSingleton<IMetodoPagamento, PagamentoPix>();
builder.Services.AddSingleton<IMetodoPagamento, PagamentoCartao>();
builder.Services.AddSingleton<IMetodoPagamento, PagamentoBoleto>();

// 4) Os negócios: "quando alguém pedir um VendaNegocio, crie um".
builder.Services.AddScoped<EstadioNegocio>();
builder.Services.AddScoped<SetorNegocio>();
builder.Services.AddScoped<AssentoNegocio>();
builder.Services.AddScoped<JogoNegocio>();
builder.Services.AddScoped<IngressoNegocio>();
builder.Services.AddScoped<UsuarioNegocio>();
builder.Services.AddScoped<VendaNegocio>();

// AddScoped = um objeto novo para cada requisição (cada clique na Web, cada chamada
// da API), jogado fora quando a resposta sai. O AddDbContext funciona do mesmo jeito:
// cada requisição ganha o seu contexto, e a conexão é fechada quando ele é descartado.

// Peça nova = uma linha nova aqui, nos DOIS Program.cs. Se esquecer uma, o sistema não
// sobe e mostra "Unable to resolve service for type ...".
// --------------------------------------------

// ---------- Só da Api (a Web usa cookie e não tem estas linhas) ----------

// Gera o token JWT no login. A chave e a validade ficam no appsettings.json, seção "Jwt".
builder.Services.AddSingleton<IGeradorDeToken, GeradorDeToken>();

// Autenticação por JWT: a Api confere o token que o app envia em "Authorization: Bearer <token>".
var jwt = builder.Configuration.GetSection("Jwt");
var chaveJwt = jwt["Chave"] ?? throw new InvalidOperationException("Jwt:Chave não encontrada no appsettings.json.");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opcoes =>
    {
        // Mantém os nomes das claims exatamente como o GeradorDeToken os escreveu.
        opcoes.MapInboundClaims = false;
        opcoes.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt["Emissor"],
            ValidateAudience = true,
            ValidAudience = jwt["Audiencia"],
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(chaveJwt)),
            ClockSkew = TimeSpan.FromMinutes(1),
            NameClaimType = ClaimTypes.Name,
            // É a claim que [Authorize(Roles = "ADMIN")] confere.
            RoleClaimType = ClaimTypes.Role
        };
    });
builder.Services.AddAuthorization();

// CORS: libera as chamadas feitas de outra origem (por exemplo, o app Flutter rodando no
// navegador). Aplicativo instalado no celular não passa por CORS. Em produção, troque
// AllowAnyOrigin pela lista de origens permitidas.
builder.Services.AddCors(opcoes =>
    opcoes.AddPolicy("AppMovel", politica => politica.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

// O filtro transforma a RegraDeNegocioException do Negócio em "400 Bad Request" com { "erro": "..." }.
builder.Services.AddControllers(opcoes => opcoes.Filters.Add<RegraDeNegocioFiltro>());

// OpenAPI: gera a documentação da API (quais endpoints existem, o que cada um
// recebe e devolve) num arquivo JSON padrão, em /openapi/v1.json.
// É esse documento que o grupo usa para mostrar ao app Flutter o que a API oferece.
builder.Services.AddOpenApi(opcoes =>
{
    // Declara que a Api usa token "Bearer": o Scalar ganha o campo para colar o token.
    opcoes.AddDocumentTransformer((documento, contexto, ct) =>
    {
        documento.Components ??= new OpenApiComponents();
        documento.Components.SecuritySchemes["Bearer"] = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Description = "Cole aqui o token devolvido por POST /api/auth/login."
        };
        return Task.CompletedTask;
    });

    // Marca com o cadeado só as rotas protegidas por [Authorize] (e não as públicas).
    opcoes.AddOperationTransformer((operacao, contexto, ct) =>
    {
        var metadados = contexto.Description.ActionDescriptor.EndpointMetadata;
        if (metadados.OfType<IAuthorizeData>().Any() && !metadados.OfType<IAllowAnonymous>().Any())
        {
            operacao.Security.Add(new OpenApiSecurityRequirement
            {
                [new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }] = Array.Empty<string>()
            });
        }
        return Task.CompletedTask;
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    // Publica o documento só durante o desenvolvimento.
    app.MapOpenApi();

    // Scalar: tela gráfica que lê o documento OpenAPI acima e permite ver e
    // testar cada endpoint pelo navegador, em /scalar.
    app.MapScalarApiReference();
}

app.UseHttpsRedirection();

app.UseCors("AppMovel");

// Primeiro descobre QUEM é o usuário (autenticação, pelo token) e só depois confere
// se ele PODE entrar na rota (autorização, pelo papel). A ordem importa.
app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
