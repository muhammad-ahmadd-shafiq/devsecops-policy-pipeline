
ARG PYTHON_VERSION=3.12-slim

# Stage 1: Builder
FROM python:${PYTHON_VERSION} AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN python -m pip install --no-cache-dir pip==25.2 && \
    python -m pip install --no-cache-dir --prefix=/install -r requirements.txt


# Stage 2: Runtime
FROM python:${PYTHON_VERSION} AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev=17.11-0+deb13u1 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 1001 appuser \
    && useradd --system --uid 1001 --gid appuser --no-create-home appuser

COPY --from=builder /install /usr/local
COPY app/ ./app/

RUN chown -R 1001:1001 /app

USER 1001:1001

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app.app:app"]
