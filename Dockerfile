# Be sure to change Erlang and Gleam versions in the github workflow also
FROM erlang:27.1.1.0-alpine AS build
COPY --from=ghcr.io/gleam-lang/gleam:v1.10.0-erlang-alpine /bin/gleam /bin/gleam
COPY . /app/
RUN cd /app && gleam export erlang-shipment

FROM erlang:27.1.1.0-alpine
ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}
RUN \
  addgroup --system gleam_packages && \
  adduser --system gleam_packages -g gleam_packages   
COPY --from=build /app/build/erlang-shipment /app
VOLUME /app/data
LABEL org.opencontainers.image.source=https://github.com/gleam-lang/packages
LABEL org.opencontainers.image.description="Gleam Packages web application"
LABEL org.opencontainers.image.licenses=Apache-2.0
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run", "server"]
