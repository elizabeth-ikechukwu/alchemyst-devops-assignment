FROM python:3.11-slim

WORKDIR /app

COPY workers/inference-worker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY workers/inference-worker/inference_worker.py .

ENV III_URL=ws://localhost:49134

CMD ["python", "inference_worker.py"]