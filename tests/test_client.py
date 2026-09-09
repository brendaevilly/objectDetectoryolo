"""Teste ponta a ponta com UM cliente.

Envia uma foto ao servidor usando o mesmo protocolo do app
(4 bytes de tamanho big-endian + JPEG) e valida a resposta JSON.

Uso:
    python3 tests/test_client.py caminho/da/foto.jpg
    python3 tests/test_client.py foto.jpg --host 192.168.1.17 --port 5000

Sem dependencias externas: so a biblioteca padrao do Python.
"""

import argparse
import json
import socket
import struct
import sys

TIMEOUT_SEGUNDOS = 30


def recv_exato(sock: socket.socket, num_bytes: int) -> bytes:
    """Le exatamente num_bytes (recv() pode retornar menos por chamada)."""
    dados = b""
    while len(dados) < num_bytes:
        pedaco = sock.recv(num_bytes - len(dados))
        if not pedaco:
            raise ConnectionError("Conexao encerrada antes de receber tudo.")
        dados += pedaco
    return dados


def enviar_foto(host: str, port: int, caminho_foto: str) -> dict:
    """Abre a conexao, envia a foto e devolve o JSON de resposta."""
    with open(caminho_foto, "rb") as f:
        imagem = f.read()

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as cliente:
        cliente.settimeout(TIMEOUT_SEGUNDOS)
        cliente.connect((host, port))

        # Pedido: 4 bytes de tamanho (big-endian) + bytes do JPEG
        cabecalho = struct.pack(">I", len(imagem))
        cliente.sendall(cabecalho + imagem)
        print(f"[ENVIADO] {len(imagem)} bytes para {host}:{port}")

        # Resposta: 4 bytes de tamanho (big-endian) + JSON
        (tamanho,) = struct.unpack(">I", recv_exato(cliente, 4))
        return json.loads(recv_exato(cliente, tamanho).decode("utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Teste de um cliente TCP")
    parser.add_argument("foto", help="caminho da imagem JPG")
    parser.add_argument("--host", default="127.0.0.1", help="IP do servidor")
    parser.add_argument("--port", type=int, default=5000, help="porta TCP")
    args = parser.parse_args()

    try:
        resposta = enviar_foto(args.host, args.port, args.foto)
    except Exception as erro:
        print(f"[FALHOU] {erro}")
        return 1

    print(f"[RESPOSTA] {json.dumps(resposta, ensure_ascii=False)}")
    labels = resposta.get("labels", [])
    if resposta.get("detected") and labels:
        print("[OK] Objetos detectados: " + ", ".join(labels))
    else:
        print("[OK] Nada detectado (resposta valida do servidor)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
