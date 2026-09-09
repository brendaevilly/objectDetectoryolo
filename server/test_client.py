import socket
import struct
import json
import sys
 
HOST = "127.0.0.1"  
PORT = 5000

def enviar_foto(caminho_foto):
    with open(caminho_foto, "rb") as f:
        dados_imagem = f.read()
 
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as cliente:
        cliente.connect((HOST, PORT))
 
        # Envia: 4 bytes de tamanho + bytes da imagem
        tamanho = struct.pack(">I", len(dados_imagem))
        cliente.sendall(tamanho + dados_imagem)
        print(f"[INFO] Imagem enviada ({len(dados_imagem)} bytes)")
 
        # Recebe: 4 bytes de tamanho + JSON de resposta
        cabecalho = cliente.recv(4)
        tamanho_resposta = struct.unpack(">I", cabecalho)[0]
 
        dados_resposta = b""
        while len(dados_resposta) < tamanho_resposta:
            dados_resposta += cliente.recv(tamanho_resposta - len(dados_resposta))
 
        resposta = json.loads(dados_resposta.decode("utf-8"))
        print(f"[INFO] Resposta do servidor: {resposta}")
 
 
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python test_client.py caminho/para/foto.jpg")
        sys.exit(1)
 
    enviar_foto(sys.argv[1])
 