
# Stage 1: Build Python dependencies
FROM python:3.12-alpine AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN python -m pip install --no-cache-dir --upgrade pip==25.2 \
    && python -m pip install --no-cache-dir --prefix=/install -r requirements.txt


# Stage 2: Minimal and patched runtime
FROM python:3.12-alpine AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Update Alpine repositories and upgrade installed OS packages
RUN apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache 'krb5-libs>=1.22.3-r0' \
    && addgroup -S -g 1001 appuser \
    && adduser -S -D -H -u 1001 -G appuser appuser

COPY --from=builder /install /usr/local
COPY --chown=1001:1001 app/ ./app/

USER 1001:1001

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app.app:app"]
