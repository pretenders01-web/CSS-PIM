using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MundialTickets.Repositorio.Migrations
{
    /// <inheritdoc />
    public partial class Inicial : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Clientes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Nome = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Email = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Cpf = table.Column<string>(type: "nchar(11)", fixedLength: true, maxLength: 11, nullable: false),
                    DataCadastro = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETDATE()"),
                    DataAtualizacao = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Ativo = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Clientes", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Clientes_Cpf",
                table: "Clientes",
                column: "Cpf",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Clientes_Email",
                table: "Clientes",
                column: "Email",
                unique: true);

            // ---------- Escrito à mão: o EF não gera trigger nem procedure ----------
            // Colocar o SQL na migration faz o "dotnet ef database update" criar tudo
            // de uma vez, em qualquer máquina, sem precisar rodar script no SSMS.

            // Trigger: toda vez que um cliente é alterado, grava a data da alteração.
            migrationBuilder.Sql(@"
CREATE TRIGGER TR_Clientes_DataAtualizacao
ON Clientes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c
       SET DataAtualizacao = GETDATE()
      FROM Clientes c
      JOIN inserted i ON i.Id = c.Id;
END");

            // Stored procedure: busca clientes por um trecho do nome.
            // Chamada pelo ClienteRepositorio.BuscarPorNomeAsync, com Dapper.
            migrationBuilder.Sql(@"
CREATE PROCEDURE sp_Clientes_BuscarPorNome
    @Trecho NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Nome, Email, Cpf, DataCadastro, DataAtualizacao, Ativo
      FROM Clientes
     WHERE Nome LIKE '%' + @Trecho + '%'
     ORDER BY Nome;
END");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS sp_Clientes_BuscarPorNome");
            // A trigger é apagada junto com a tabela.

            migrationBuilder.DropTable(
                name: "Clientes");
        }
    }
}
