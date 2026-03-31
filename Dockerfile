FROM python:3.11-slim

WORKDIR /app

COPY app.py test_app.py ./

CMD ["python3", "app.py"]
