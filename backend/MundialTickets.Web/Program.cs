using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos.Pagamentos;
using MundialTickets.Negocio;
using MundialTickets.Repositorio;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

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
// ATENÇÃO: este bloco é IGUAL no Program.cs da Api. Mudou aqui, mude lá também.

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

builder.Services.AddControllersWithViews();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
