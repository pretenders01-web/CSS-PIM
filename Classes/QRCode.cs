using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{

    // Classe responsavel por representar o QR Code de validacao do ingresso
    public class QRCode
    {
        // Identificador unico do QR Code
        public int QRCodeID { get; private set; }

        // Identificador da venda associada ao QR Code
        public int VendaID { get; private set; }

        // Identificador do ingresso associado ao QR Code
        public int IngressoID { get; private set; }

        // Codigo gerado para validacao do ingresso
        public string CodigoQR { get; private set; }

        // Data de expiracao do QR Code
        public DateTime DataExpiracao { get; private set; }

        // Indica se o QR Code ja foi utilizado ou nao
        public bool Utilizado { get; private set; }

        // Construtor vazio
        public QRCode() { }

        // Construtor responsavel por criar um QR Code
        public QRCode(int qrCodeID, int vendaID, int ingressoID, string codigoQR, DateTime dataExpiracao, bool utilizado)
        {
            QRCodeID = qrCodeID;
            VendaID = vendaID;
            IngressoID = ingressoID;
            CodigoQR = codigoQR;
            DataExpiracao = dataExpiracao;
            Utilizado = utilizado;
        }
    }
}
