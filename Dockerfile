FROM python:3.12.11-slim AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /build

COPY requirements.txt .
RUN python -m pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12.11-slim as runtime

ENV DONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
        PATH="/usr/local/bin=$PATH"

COPY --from=builder /install /usr/local
COPY app/ ./app/

RUN groupadd --gid 10001 appuser \
    && useradd --uid 10001 --gid appuser --no-create-home appuser

USER 10001:10001

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers","2","app.app=app"]

