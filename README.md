# Gleam Packages

📦 Search for Gleam packages on [Hex](https://hex.pm).

A Gleam application using the [Wisp](https://gleam-wisp.github.io/wisp) web framework,
served with the [Mist](https://github.com/rawhat/mist) web server, using a
[Stóráil](https://github.com/lpil/storail) database.

## Environment variables

The application is configured with a series of environment variables.

- `HEX_API_KEY` - **Required**. A read-only API key for the Hex API. You can
  generate one via [the Hex dashboard](https://hex.pm/dashboard/keys).
- `DATABASE_PATH` - A path where the Stóráil database will be stored. Defaults
  to `./storage`.

## Local development

Install Gleam! See `./Dockerfile` for which version is used in production.

```shell
gleam test        # Run the tests
gleam run server  # Run the server
```

## Deployment

```ini
[Unit]
Description=Gleam packages index web application
After=local-fs.target

[Container]
Image=ghcr.io/gleam-lang/packages:main

# Make podman-auto-update.service update it when there's a new image version
AutoUpdate=registry

# Expose the port the app is listening on
PublishPort=3000:3000

# Mount the storage
Volume=/srv/packages-storage:/storage:rw,z
Environment=DATABASE_PATH=/storage

# Provide the secrets
EnvironmentFile=/srv/packages-environment

# Restart the service if the homepage no longer loads
HealthCmd=sh -c /app/healthcheck.sh
HealthInterval=30s
HealthTimeout=5s
HealthRetries=3
HealthOnFailure=restart

[Install]
WantedBy=multi-user.target default.target
```

Podman will check for new image versions once and hour, and upgrade the
container if needed, so new commits to main will be auto-deployed within an
hour.

You can `ssh linuxuser@packages.gleam.run` if you need to do something on the
server.
