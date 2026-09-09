import socket
import struct

def recv_exact(sock: socket.socket, num_bytes: int) -> bytes:
    """Lê exatamente num_bytes do socket, mesmo que recv() retorne menos de uma vez."""
    data = b""
    while len(data) < num_bytes:
        chunk = sock.recv(num_bytes - len(data))
        if not chunk:
            raise ConnectionError("Conexão encerrada antes de receber todos os dados esperados.")
        data += chunk
    return data

def recv_message(sock: socket.socket) -> bytes:
    header = recv_exact(sock, 4)
    (size,) = struct.unpack(">I", header)
    return recv_exact(sock, size)

def send_message(sock: socket.socket, payload: bytes) -> None:
    header = struct.pack(">I", len(payload))
    sock.sendall(header + payload)
