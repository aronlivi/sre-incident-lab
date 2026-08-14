FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /code

COPY app/requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir \
    -r /code/requirements.txt

COPY app/src /code/app/src

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/live', timeout=2)" || exit 1

CMD ["uvicorn", "app.src.main:app", "--host", "0.0.0.0", "--port", "8000"]
