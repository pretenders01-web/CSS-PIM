using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;

namespace MundialTickets.Repositorio.Contexto;

// O DbContext é a "porta" do Entity Framework Core para o banco.
// Cada DbSet vira uma tabela.
public class AppDbContext : DbContext
{
    // As "options" trazem qual banco usar (SQL Server) e a connection string.
    // Elas são montadas pela linha AddDbContext do Program.cs e entregues aqui.
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Cliente> Clientes => Set<Cliente>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Cliente>(e =>
        {
            e.ToTable("Clientes", t =>
            {
                // OBRIGATÓRIO a partir do EF Core 7 em tabela que tem trigger.
                // Sem esta linha, todo INSERT/UPDATE em Clientes dá erro,
                // porque o EF usa OUTPUT, que o SQL Server não aceita com trigger.
                t.HasTrigger("TR_Clientes_DataAtualizacao");
            });

            e.HasKey(c => c.Id);
            e.Property(c => c.Nome).HasMaxLength(100).IsRequired();
            e.Property(c => c.Email).HasMaxLength(150).IsRequired();
            e.Property(c => c.Cpf).HasMaxLength(11).IsFixedLength().IsRequired();
            e.Property(c => c.DataCadastro).HasDefaultValueSql("GETDATE()");

            // Índices únicos: o banco também barra e-mail e CPF repetidos.
            e.HasIndex(c => c.Email).IsUnique();
            e.HasIndex(c => c.Cpf).IsUnique();
        });
    }
}
