"""Teste de CONCORRENCIA: varios clientes enviam fotos ao mesmo tempo.

Simula o cenario da demonstracao com dois ou mais celulares analisando
fotos simultaneamente. Cada cliente roda em uma thread, como se fosse um
aparelho diferente. Falha se qualquer cliente nao receber resposta valida
ou se o servidor demorar mais que o timeout do app (30s).

Uso:
    python3 tests/test_concurrent.py caminho/da/foto.jpg
    python3 tests/test_concurrent.py foto.jpg --host 192.168.1.17 --clients 3
"""

import argparse
import json
import socket
import struct
import sys
import threading
import time

TIMEOUT_SEGUNDOS = 30  # mesmo valor de AppConfig.responseTimeout no app


def recv_exato(sock: socket.socket, num_bytes: int) -> bytes:
    """Le exatamente num_bytes (recv() pode retornar menos por chamada)."""
    dados = b""
    while len(dados) < num_bytes:
        pedaco = sock.recv(num_bytes - len(dados))
        if not pedaco:
            raise ConnectionError("Conexao encerrada antes de receber tudo.")
        dados += pedaco
    return dados


def enviar_foto(host: str, port: int, imagem: bytes, resultados: dict, id_cliente: int) -> None:
    """Executa o ciclo completo de um cliente e registra (tempo, resposta)."""
    inicio = time.time()
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as cliente:
            cliente.settimeout(TIMEOUT_SEGUNDOS)
            cliente.connect((host, port))
            cliente.sendall(struct.pack(">I", len(imagem)) + imagem)

            (tamanho,) = struct.unpack(">I", recv_exato(cliente, 4))
            resposta = json.loads(recv_exato(cliente, tamanho).decode("utf-8"))

        resultados[id_cliente] = {
            "segundos": round(time.time() - inicio, 2),
            "detected": resposta.get("detected", False),
            "labels": resposta.get("labels", []),
        }
    except Exception as erro:
        resultados[id_cliente] = {"segundos": round(time.time() - inicio, 2), "erro": str(erro)}


def main() -> int:
    parser = argparse.ArgumentParser(description="Teste de clientes simultaneos")
    parser.add_argument("foto", help="caminho da imagem JPG")
    parser.add_argument("--host", default="127.0.0.1", help="IP do servidor")
    parser.add_argument("--port", type=int, default=5000, help="porta TCP")
    parser.add_argument("--clients", type=int, default=2, help="numero de clientes simultaneos")
    args = parser.parse_args()

    with open(args.foto, "rb") as f:
        imagem = f.read()

    resultados: dict[int, dict] = {}
    threads = [
        threading.Thread(target=enviar_foto, args=(args.host, args.port, imagem, resultados, i))
        for i in range(args.clients)
    ]

    print(f"[TESTE] Disparando {args.clients} clientes simultaneos contra {args.host}:{args.port}...")
    inicio = time.time()
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    total = round(time.time() - inicio, 2)

    falhas = 0
    for i in range(args.clients):
        r = resultados[i]
        if "erro" in r:
            falhas += 1
            print(f"  Cliente {i}: FALHOU em {r['segundos']}s -> {r['erro']}")
        else:
            print(f"  Cliente {i}: OK em {r['segundos']}s -> {r['labels']}")

    print(f"[RESUMO] {args.clients - falhas}/{args.clients} clientes atendidos em {total}s no total")
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
