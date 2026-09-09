import json
import os
import socket
from datetime import datetime

from config import HOST, PORT, MODEL_NAME
from detector import ObjectDetector
from protocol import recv_message, send_message

RECEIVED_DIR = os.path.join(os.path.dirname(__file__), "received")

def save_image(jpeg_bytes: bytes) -> str:
    os.makedirs(RECEIVED_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = os.path.join(RECEIVED_DIR, f"foto_{timestamp}.jpg")
    with open(path, "wb") as f:
        f.write(jpeg_bytes)
    return path

def build_response(labels: list[str]) -> bytes:
    """Monta o JSON esperado pelo app: detected, labels, message."""
    if labels:
        message = "\n".join(f"{label} detectada" if label == "Pessoa" else f"{label} detectado" for label in labels)
        payload = {"detected": True, "labels": labels, "message": message}
    else:
        payload = {"detected": False, "labels": [], "message": "Nada Detectado"}
    return json.dumps(payload, ensure_ascii=False).encode("utf-8")

def handle_connection(conn: socket.socket, addr, detector: ObjectDetector) -> None:
    print(f"[INFO] Conexão recebida de {addr}")
    try:
        jpeg_bytes = recv_message(conn)
        save_image(jpeg_bytes)
 
        image = detector.decode_jpeg(jpeg_bytes)
        labels = detector.detect(image)
        print(f"[INFO] Objetos detectados: {labels}")
 
        response = build_response(labels)
        send_message(conn, response)
    except Exception as error:
        print(f"[ERRO] Falha ao processar conexão: {error}")
    finally:
        conn.close()

    
def main() -> None:
    print(f"[INFO] Carregando modelo {MODEL_NAME}...")
    detector = ObjectDetector(MODEL_NAME)
    print("[INFO] Modelo carregado com sucesso.")
 
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((HOST, PORT))
        server.listen(1)
        print(f"[INFO] Servidor ouvindo em {HOST}:{PORT}")
        print("[INFO] Aguardando imagem...")
 
        while True:
            conn, addr = server.accept()
            handle_connection(conn, addr, detector)
            print("[INFO] Aguardando imagem...")


if __name__ == "__main__":
    main()
