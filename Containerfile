# -*- coding: utf-8; mode: dockerfile; -*-
FROM docker.io/library/debian:11-slim
LABEL maintainer="Tom Vaughan <tvaughan@tocino.cl>"

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

RUN apt -q update                                                               \
    && DEBIAN_FRONTEND=noninteractive                                           \
    apt-get -q -y install                                                       \
        make                                                                    \
        netcat-openbsd                                                          \
    && apt -q clean                                                             \
    && rm -rf /var/lib/apt/lists/*

COPY hello-world-container /opt/hello-world-container

WORKDIR /opt/hello-world-container

ENV PORT=3000

CMD ["make", "run"]
