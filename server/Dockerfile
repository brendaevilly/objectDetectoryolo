FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# ultralytics puxa opencv-python (com GUI, precisa de libGL/libxcb); trocamos pela
# variante headless numa camada separada para reaproveitar o cache das anteriores.
RUN pip uninstall -y opencv-python opencv-python-headless \
    && pip install --no-cache-dir opencv-python-headless

COPY . .

EXPOSE 5000
# -u: sem buffer de stdout, para os logs [INFO] aparecerem no docker logs
CMD ["python", "-u", "main.py"]
