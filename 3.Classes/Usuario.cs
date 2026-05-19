using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{
    // Classe responsável por representar um usuário do sistema
    public class Usuario : IValidavel
    {
        // Identificador único do usuario
        public int UsuarioID { get; private set; }
        // Nome do usuário cadastrado
        public string Nome { get; private set; }
        // Email utilizado pelo usuário para login ou contato
        public string Email { get; private set; }
        // Senha armazenada em formato de hash, para maior segurança
        public string SenhaHash { get; private set; }
        // CPF do usuario
        public string CPF { get; private set; }
        // Data em que o usuário foi cadastrado no sistema
        public DateTime DataCadastro { get; private set; }
        // Indica se o usuário está ativo ou não no sistema
        public bool Ativo { get; private set; }
        // Construtor vazio
        public Usuario() { }

        // Construtor responsável por criar um novo usuário com os dados principais
        public Usuario(int usuarioID, string nome, string email, string senhaHash, string cpf)
        {
            UsuarioID = usuarioID;
            Nome = nome;
            Email = email;
            SenhaHash = senhaHash;
            CPF = cpf;
            // Define automaticamente a data de cadastro como a data atual
            DataCadastro = DateTime.Now;
            // Todo usuário criado começa ativo no sistema
            Ativo = true;
        }

        public bool Validar()
        {
            return !string.IsNullOrWhiteSpace(Nome)
            && !string.IsNullOrWhiteSpace(Email)
            && Email.Contains("@")
            && !string.IsNullOrWhiteSpace(CPF);
        }
    }
}
