using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;

namespace MundialTickets.Repositorio.Contexto;

// O DbContext é a "porta" do Entity Framework Core para o banco.
// Cada DbSet vira uma tabela.
// O banco CopaDoMundoVendas é criado pelos scripts de 5.database (00 a 04),
// não por migrations: aqui o EF só MAPEIA as tabelas que já existem.
public class AppDbContext : DbContext
{
    // As "options" trazem qual banco usar (SQL Server) e a connection string.
    // Elas são montadas pela linha AddDbContext do Program.cs e entregues aqui.
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Estadio> Estadios => Set<Estadio>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Estadio>(e =>
        {
            e.ToTable("Estadio");
            e.HasKey(x => x.EstadioID);
            e.Property(x => x.Nome).HasMaxLength(100).IsRequired();
            e.Property(x => x.Cidade).HasMaxLength(100).IsRequired();
            e.Property(x => x.CapacidadeTotal).IsRequired();
        });

        // Quando a entidade ItemVenda for mapeada, lembrar do HasTrigger para as
        // três triggers da tabela (trg_ItemVenda_Insert, _UpdateValorTotal e
        // _GerarQRCode). Sem ele, todo INSERT em ItemVenda dá erro no EF Core 7+.
    }
}
