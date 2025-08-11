ARG ERLANG_VERSION=28.0.2.0
ARG GLEAM_VERSION=v1.12.0

# Gleam stage
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

# Build stage
FROM erlang:${ERLANG_VERSION}-alpine AS build
COPY --from=gleam /bin/gleam /bin/gleam
COPY . /app/
RUN cd /app && gleam export erlang-shipment

# Final stage
FROM erlang:${ERLANG_VERSION}
ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}
RUN addgroup --system gleam_packages && \
    adduser --system gleam_packages -g gleam_packages
COPY --from=build /app/build/erlang-shipment /app
VOLUME /app/data
LABEL org.opencontainers.image.source=https://github.com/gleam-lang/packages
LABEL org.opencontainers.image.description="Gleam Packages web application"
LABEL org.opencontainers.image.licenses=Apache-2.0
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run", "server"]
