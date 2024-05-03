# dockerfile to deploy fastapi applications built with poetry (uses a single core)

FROM python:3.11-slim-bookworm AS build-deps

# use poetry to generate requirements.txt
RUN pip install "poetry==1.8.2"
COPY pyproject.toml poetry.lock /tmp/
RUN python -m poetry export --without dev --directory /tmp --output /tmp/requirements.txt
RUN pip uninstall -y poetry

FROM python:3.11-slim-bookworm AS install-deps

# install dependencies from requirements.txt
COPY --from=build-deps /tmp/requirements.txt /tmp/requirements.txt
RUN pip install --disable-pip-version-check -r /tmp/requirements.txt
RUN pip uninstall -y pip

FROM gcr.io/distroless/python3-debian12:latest AS deploy

# copy over site-packages dir
COPY --from=install-deps /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages

# add app scripts to workdir
WORKDIR /usr/src/app
COPY backend .

EXPOSE 80
CMD ["-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
