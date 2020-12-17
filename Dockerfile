FROM python:3.8-alpine as base
LABEL version=0.1
LABEL maintainer="Yogesh Girikumar <yogesh.girikumar@hotosm.org>"
LABEL description="Builds backend docker image"

WORKDIR /usr/src/app

FROM base as builder

# Setup backend build dependencies
RUN apk update && \
    apk add \
        postgresql-dev \
        gcc \
        python3-dev \
        musl-dev \
        libffi-dev \
        geos-dev \
        proj-util \
        proj-dev \
        make

COPY requirements.txt .

RUN pip install \
    --prefix=/install \
    --no-cache-dir \
    --no-warn-script-location \
    -r requirements.txt

FROM base

RUN apk update && \
    apk add \
        postgresql-libs geos proj-util

COPY --from=builder /install /usr/local
COPY backend backend/
COPY migrations migrations/
COPY scripts/world scripts/world/
COPY scripts/database scripts/database/
COPY manage.py .

ENV TZ UTC # Fix timezone (do not change - see issue #3638)
EXPOSE 5000
CMD ["gunicorn", "-c", "python:backend.gunicorn", "manage:application"]