import socket
import struct


def recv_message(sock: socket.socket) -> bytes:
    # TODO: 4 bytes (tamanho big-endian) + payload
    raise NotImplementedError


def send_message(sock: socket.socket, payload: bytes) -> None:
    # TODO: 4 bytes (tamanho big-endian) + payload
    raise NotImplementedError
