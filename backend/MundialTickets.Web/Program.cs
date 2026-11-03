using System.Globalization;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Localization;
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

// ---------- Só da Web (a Api usa JWT e não tem estas linhas) ----------

// Login por COOKIE: depois de entrar, o navegador manda o cookie em cada requisição.
// O perfil (CLIENTE ou ADMIN) vai dentro do cookie e é o que [Authorize(Roles = "ADMIN")] confere.
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(opcoes =>
    {
        opcoes.LoginPath = "/Conta/Entrar";
        opcoes.LogoutPath = "/Conta/Sair";
        opcoes.AccessDeniedPath = "/Conta/AcessoNegado";
        opcoes.Cookie.Name = "MundialTickets.Login";
        opcoes.Cookie.HttpOnly = true;
        opcoes.Cookie.SameSite = SameSiteMode.Lax;
        opcoes.ExpireTimeSpan = TimeSpan.FromHours(8);
        opcoes.SlidingExpiration = true;

        // A cada requisição, confere se a conta continua existindo, ativa e com o mesmo perfil.
        // Assim uma conta desativada, ou um usuário promovido a ADMIN, vale já na hora, sem
        // esperar o cookie vencer.
        opcoes.Events = new CookieAuthenticationEvents
        {
            OnValidatePrincipal = async contexto =>
            {
                var caminho = contexto.Request.Path;
                if (caminho.StartsWithSegments("/css") || caminho.StartsWithSegments("/js") || caminho.StartsWithSegments("/lib")
                    || caminho.StartsWithSegments("/img") || caminho.StartsWithSegments("/flags"))
                    return;   // arquivos estáticos não precisam consultar o banco

                var usuarioId = contexto.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
                var perfilNoCookie = contexto.Principal?.FindFirstValue(ClaimTypes.Role);
                var usuario = int.TryParse(usuarioId, out var id)
                    ? contexto.HttpContext.RequestServices.GetRequiredService<UsuarioNegocio>().ObterPorId(id)
                    : null;

                if (usuario is null || !usuario.Ativo || usuario.Perfil != perfilNoCookie)
                {
                    contexto.RejectPrincipal();
                    await contexto.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                }
            }
        };
    });
builder.Services.AddAuthorization();

// Sessão do ASP.NET Core: é onde o carrinho de compras fica guardado (só os ids dos ingressos).
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(opcoes =>
{
    opcoes.Cookie.Name = "MundialTickets.Sessao";
    opcoes.Cookie.HttpOnly = true;
    opcoes.Cookie.IsEssential = true;
    opcoes.IdleTimeout = TimeSpan.FromHours(2);
});

builder.Services.AddControllersWithViews();

var app = builder.Build();

// Cultura invariante para LER os formulários: o <input type="number"> envia "95.50" (com ponto)
// e, com a cultura do Windows em português, o servidor leria isso como 9550. A exibição em
// formato brasileiro (R$ 95,50 e 11/06/2026) é feita à parte, pela classe Formatacao.
var culturaInvariante = CultureInfo.InvariantCulture;
app.UseRequestLocalization(new RequestLocalizationOptions
{
    DefaultRequestCulture = new RequestCulture(culturaInvariante),
    SupportedCultures = new List<CultureInfo> { culturaInvariante },
    SupportedUICultures = new List<CultureInfo> { culturaInvariante }
});

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseSession();

// Primeiro descobre QUEM é o usuário (autenticação, pelo cookie) e só depois confere
// se ele PODE entrar na página (autorização, pelo perfil). A ordem importa.
app.UseAuthentication();
app.UseAuthorization();

app.MapStaticAssets();

// A área de Administração (/Admin/...) vem primeiro; depois a rota normal do site.
app.MapControllerRoute(
    name: "areas",
    pattern: "{area:exists}/{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();

app.Run();