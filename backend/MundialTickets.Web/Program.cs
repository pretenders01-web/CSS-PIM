using Microsoft.EntityFrameworkCore;
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

// 2) O repositório: "quando alguém pedir um IEstadioRepositorio (a interface),
//    entregue um EstadioRepositorio (a classe)".
builder.Services.AddScoped<IEstadioRepositorio, EstadioRepositorio>();

// 3) O negócio: "quando alguém pedir um EstadioNegocio, crie um".
builder.Services.AddScoped<EstadioNegocio>();

// AddScoped = um objeto novo para cada requisição (cada clique na Web, cada chamada
// da API), jogado fora quando a resposta sai. O AddDbContext funciona do mesmo jeito:
// cada requisição ganha o seu contexto, e a conexão é fechada quando ele é descartado.

// Cada entidade nova ganha duas linhas aqui, uma de repositório e uma de negócio:
// builder.Services.AddScoped<IIngressoRepositorio, IngressoRepositorio>();
// builder.Services.AddScoped<IngressoNegocio>();
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
