import cv2
import numpy as np
from ultralytics import YOLO

CONFIDENCE_THRESHOLD = 0.5

LABEL_TRANSLATION = {
    "person": "Pessoa",
    "car": "Carro",
    "chair": "Cadeira",
    "backpack": "Mochila",
    
}


class ObjectDetector:
    def __init__(self, model_name: str = "yolo11n.pt") -> None:
        self.model = YOLO(model_name)

    def detect(self, image_bgr: np.ndarray) -> list[str]:
        results = self.model(image_bgr, verbose=False)
 
        labels: list[str] = []
        for result in results:
            for box in result.boxes:
                confidence = float(box.conf[0])
                if confidence < CONFIDENCE_THRESHOLD:
                    continue
                class_name_en = self.model.names[int(box.cls[0])]
                class_name_pt = LABEL_TRANSLATION.get(class_name_en, class_name_en)
                if class_name_pt not in labels:
                    labels.append(class_name_pt)
 
        return labels
    
    @staticmethod
    def decode_jpeg(jpeg_bytes: bytes) -> np.ndarray:
        """Converte bytes JPEG recebidos pelo socket em uma imagem OpenCV (BGR)."""
        array = np.frombuffer(jpeg_bytes, dtype=np.uint8)
        image = cv2.imdecode(array, cv2.IMREAD_COLOR)
        if image is None:
            raise ValueError("Não foi possível decodificar a imagem recebida.")
        return image


