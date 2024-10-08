FROM python:3

RUN set -eux; apt-get update; apt-get install -y --no-install-recommends git jq ; rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir yq mkdocs mkdocs-material pymdown-extensions mike
