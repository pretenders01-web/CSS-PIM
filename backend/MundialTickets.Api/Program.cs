using Microsoft.EntityFrameworkCore;
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
// criar uma peça. Depois, quando um controller pede um ClienteNegocio no
// construtor, o ASP.NET monta a cadeia inteira sozinho:
//
//   ClientesController  pede  ClienteNegocio
//   ClienteNegocio      pede  IClienteRepositorio  -> recebe um ClienteRepositorio
//   ClienteRepositorio  pede  AppDbContext         -> recebe com a connection string
//
// Ninguém escreve "new" para essas classes. Explicação passo a passo, com os
// erros mais comuns: INJECAO-DE-DEPENDENCIA.md, na pasta da solution.
//
// ATENÇÃO: este bloco é IGUAL no Program.cs da Web. Mudou aqui, mude lá também.

// 1) O banco: "quando alguém pedir um AppDbContext, crie um usando SQL Server
//    e esta connection string".
builder.Services.AddDbContext<AppDbContext>(opcoes => opcoes.UseSqlServer(connectionString));

// 2) O repositório: "quando alguém pedir um IClienteRepositorio (a interface),
//    entregue um ClienteRepositorio (a classe)".
builder.Services.AddScoped<IClienteRepositorio, ClienteRepositorio>();

// 3) O negócio: "quando alguém pedir um ClienteNegocio, crie um".
builder.Services.AddScoped<ClienteNegocio>();

// AddScoped = um objeto novo para cada requisição (cada clique na Web, cada chamada
// da API), jogado fora quando a resposta sai. O AddDbContext funciona do mesmo jeito:
// cada requisição ganha o seu contexto, e a conexão é fechada quando ele é descartado.

// Cada entidade nova ganha duas linhas aqui, uma de repositório e uma de negócio:
// builder.Services.AddScoped<IIngressoRepositorio, IngressoRepositorio>();
// builder.Services.AddScoped<IngressoNegocio>();
// --------------------------------------------

builder.Services.AddControllers();

// OpenAPI: gera a documentação da API (quais endpoints existem, o que cada um
// recebe e devolve) num arquivo JSON padrão, em /openapi/v1.json.
// É esse documento que o grupo usa para mostrar ao app Flutter o que a API oferece.
builder.Services.AddOpenApi();

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

app.UseAuthorization();

app.MapControllers();

app.Run();
