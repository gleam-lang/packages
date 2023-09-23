FROM ghcr.io/gleam-lang/gleam:v0.31.0-rc1-erlang-alpine

# Add LiteFS binary, to replicate the SQLite database.
COPY --from=flyio/litefs:0.5 /usr/local/bin/litefs /usr/local/bin/litefs

# Add project code
COPY . /build/

# Compile the Gleam application
RUN cd /build \
  && apk add fuse3 ca-certificates sqlite gcc build-base \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build \
  && apk del gcc build-base

COPY litefs.yml /etc/litefs.yml

# Run the application
WORKDIR /app
ENTRYPOINT litefs mount
