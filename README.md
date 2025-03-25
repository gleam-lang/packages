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
Description=My Gleam web application
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

[Install]
WantedBy=multi-user.target default.target
```
