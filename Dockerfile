FROM ghcr.io/gleam-lang/gleam:v0.28.3-erlang-alpine

# Add project code
COPY . /build/

# Compile the Gleam application
RUN cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build \
  && apk del gcc build-base \
  && addgroup -S packages \
  && adduser -S packages -G packages \
  && chown -R packages /app

# Run the application
USER packages
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run", "server"]
