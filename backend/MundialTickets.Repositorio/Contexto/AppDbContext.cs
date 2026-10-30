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
    public DbSet<Setor> Setores => Set<Setor>();
    public DbSet<Assento> Assentos => Set<Assento>();
    public DbSet<Jogo> Jogos => Set<Jogo>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Ingresso> Ingressos => Set<Ingresso>();
    public DbSet<Venda> Vendas => Set<Venda>();
    public DbSet<ItemVenda> ItensVenda => Set<ItemVenda>();
    public DbSet<QRCode> QRCodes => Set<QRCode>();

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

        // Em todas as chaves estrangeiras abaixo, OnDelete(Restrict) espelha o banco:
        // as FKs dele não apagam em cascata, elas recusam a exclusão de quem tem vínculos.

        modelBuilder.Entity<Setor>(e =>
        {
            e.ToTable("Setor");
            e.HasKey(x => x.SetorID);
            e.Property(x => x.NomeSetor).HasMaxLength(50).IsRequired();
            e.Property(x => x.PrecoBase).HasColumnType("decimal(10,2)");

            e.HasOne(x => x.Estadio).WithMany()
                .HasForeignKey(x => x.EstadioID).OnDelete(DeleteBehavior.Restrict);

            // O banco já tem este índice único (UQ_Setor_Estadio); aqui só o documentamos.
            e.HasIndex(x => new { x.EstadioID, x.NomeSetor }).IsUnique();
        });

        modelBuilder.Entity<Assento>(e =>
        {
            e.ToTable("Assento");
            e.HasKey(x => x.AssentoID);
            e.Property(x => x.Numero).HasMaxLength(10).IsRequired();

            e.HasOne(x => x.Setor).WithMany(s => s.Assentos)
                .HasForeignKey(x => x.SetorID).OnDelete(DeleteBehavior.Restrict);

            e.HasIndex(x => new { x.SetorID, x.Numero }).IsUnique();
        });

        modelBuilder.Entity<Jogo>(e =>
        {
            e.ToTable("Jogo");
            e.HasKey(x => x.JogoID);
            e.Property(x => x.DataHora).HasColumnType("datetime");
            e.Property(x => x.TimeA).HasMaxLength(50).IsRequired();
            e.Property(x => x.TimeB).HasMaxLength(50).IsRequired();
            e.Property(x => x.Fase).HasMaxLength(30).IsRequired();

            e.HasOne(x => x.Estadio).WithMany()
                .HasForeignKey(x => x.EstadioID).OnDelete(DeleteBehavior.Restrict);

            e.HasIndex(x => new { x.EstadioID, x.DataHora }).IsUnique();
        });

        modelBuilder.Entity<Usuario>(e =>
        {
            e.ToTable("Usuario");
            e.HasKey(x => x.UsuarioID);
            e.Property(x => x.Nome).HasMaxLength(100).IsRequired();
            e.Property(x => x.Email).HasMaxLength(150).IsRequired();
            e.Property(x => x.SenhaHash).HasMaxLength(255).IsRequired();
            e.Property(x => x.CPF).HasMaxLength(14);
            e.Property(x => x.Perfil).HasMaxLength(20).IsRequired();

            // O banco preenche a data de cadastro (default getdate()). NÃO configurar valor
            // padrão em Ativo: o EF Core ignora o valor false quando a coluna tem padrão no
            // banco, e um usuário criado inativo viraria ativo.
            e.Property(x => x.DataCadastro).HasColumnType("datetime").HasDefaultValueSql("GETDATE()");

            e.HasIndex(x => x.Email).IsUnique();
        });

        modelBuilder.Entity<Ingresso>(e =>
        {
            e.ToTable("Ingresso");
            e.HasKey(x => x.IngressoID);
            e.Property(x => x.NumeroAssento).HasMaxLength(10);
            e.Property(x => x.PrecoFinal).HasColumnType("decimal(10,2)");
            e.Property(x => x.Status).HasMaxLength(20).IsRequired();
            e.Property(x => x.DataCriacao).HasColumnType("datetime").HasDefaultValueSql("GETDATE()");

            e.HasOne(x => x.Jogo).WithMany()
                .HasForeignKey(x => x.JogoID).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Setor).WithMany()
                .HasForeignKey(x => x.SetorID).OnDelete(DeleteBehavior.Restrict);

            // O assento é opcional no banco (AssentoID nulo).
            e.HasOne(x => x.Assento).WithMany()
                .HasForeignKey(x => x.AssentoID).IsRequired(false).OnDelete(DeleteBehavior.Restrict);

            // Mesmo assento não pode ter dois ingressos no mesmo jogo; vale só quando há assento.
            e.HasIndex(x => new { x.JogoID, x.SetorID, x.AssentoID })
                .IsUnique().HasFilter("[AssentoID] IS NOT NULL");
        });

        modelBuilder.Entity<Venda>(e =>
        {
            e.ToTable("Venda");
            e.HasKey(x => x.VendaID);
            e.Property(x => x.DataVenda).HasColumnType("datetime").HasDefaultValueSql("GETDATE()");
            e.Property(x => x.ValorTotal).HasColumnType("decimal(10,2)");
            e.Property(x => x.StatusPagamento).HasMaxLength(20).IsRequired();
            e.Property(x => x.MetodoPagamento).HasMaxLength(30);

            e.HasOne(x => x.Usuario).WithMany(u => u.Vendas)
                .HasForeignKey(x => x.UsuarioID).OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ItemVenda>(e =>
        {
            // OBRIGATÓRIO a partir do EF Core 7 em tabela que tem trigger: ItemVenda tem três.
            // Sem estas linhas, todo INSERT em ItemVenda feito pelo EF dá erro, porque o EF usa
            // OUTPUT, que o SQL Server não aceita em tabela com trigger.
            e.ToTable("ItemVenda", t =>
            {
                t.HasTrigger("trg_ItemVenda_Insert");
                t.HasTrigger("trg_ItemVenda_UpdateValorTotal");
                t.HasTrigger("trg_ItemVenda_GerarQRCode");
            });

            e.HasKey(x => x.ItemVendaID);
            e.Property(x => x.PrecoUnitario).HasColumnType("decimal(10,2)");

            e.HasOne(x => x.Venda).WithMany(v => v.Itens)
                .HasForeignKey(x => x.VendaID).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Ingresso).WithMany()
                .HasForeignKey(x => x.IngressoID).OnDelete(DeleteBehavior.Restrict);

            // Um ingresso só pode estar em uma venda.
            e.HasIndex(x => x.IngressoID).IsUnique();
        });

        modelBuilder.Entity<QRCode>(e =>
        {
            e.ToTable("QRCode");
            e.HasKey(x => x.QRCodeID);
            e.Property(x => x.CodigoQR).HasMaxLength(255).IsRequired();
            e.Property(x => x.DataExpiracao).HasColumnType("datetime");

            e.HasOne(x => x.Venda).WithMany()
                .HasForeignKey(x => x.VendaID).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Ingresso).WithMany()
                .HasForeignKey(x => x.IngressoID).OnDelete(DeleteBehavior.Restrict);

            e.HasIndex(x => x.IngressoID).IsUnique();
            e.HasIndex(x => x.CodigoQR).IsUnique();
        });
    }
}
