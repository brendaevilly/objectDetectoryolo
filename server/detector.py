import cv2
import numpy as np
from ultralytics import YOLO


class ObjectDetector:
    def __init__(self, model_name: str = "yolo11n.pt") -> None:
        # TODO: carregar YOLO11n ou YOLOv8n
        raise NotImplementedError

    def detect(self, image_bgr: np.ndarray) -> list[str]:
        # TODO: inferência e lista de objetos
        raise NotImplementedError
