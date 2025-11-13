ARG PYTHON_VERSION=3.13

FROM node:alpine AS build_ts

ENV VITE_BASE_API=/api/

COPY . /code

WORKDIR /code/app/dashboard

RUN npm install typescript@latest --legacy-peer-deps

RUN npm run build

FROM python:$PYTHON_VERSION-slim AS build_python

ENV PYTHONUNBUFFERED=1

WORKDIR /code

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential curl unzip gcc python3-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY ./install_latest_xray.sh /code/
RUN bash install_latest_xray.sh

COPY ./requirements.txt /code/
RUN python3 -m pip install --upgrade pip setuptools \
    && pip install --no-cache-dir --upgrade -r /code/requirements.txt

FROM python:$PYTHON_VERSION-slim

ENV PYTHON_LIB_PATH=/usr/local/lib/python${PYTHON_VERSION%.*}/site-packages
WORKDIR /code

RUN rm -rf $PYTHON_LIB_PATH/*

COPY --from=build_python $PYTHON_LIB_PATH $PYTHON_LIB_PATH
COPY --from=build_python /usr/local/bin /usr/local/bin
COPY --from=build_python /usr/local/share/xray /usr/local/share/xray

COPY . /code
COPY --from=build_ts /code/app/dashboard/build /code/app/dashboard/build

RUN cp /code/app/dashboard/build/index.html /code/app/dashboard/build/404.html

RUN ln -s /code/marzban-cli.py /usr/bin/marzban-cli \
    && chmod +x /usr/bin/marzban-cli \
    && marzban-cli completion install --shell bash

CMD ["bash", "-c", "alembic upgrade head; python main.py"]
