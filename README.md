# Gleam Packages

📦 Search for Gleam packages on [Hex](https://hex.pm).

A Gleam application served with the [Mist](https://github.com/rawhat/mist) web
server, using a SQLite database.

The application is deployed on [Fly](https://fly.io) where
[LiteFS](https://github.com/superfly/litefs) is used to replicate the
SQLite database across all instances of the application.

## Environment variables

The application is configured with a series of environment variables.

- `HEX_API_KEY` - **Required**. A read-only API key for the Hex API. You can
  generate one via [the Hex dashboard](https://hex.pm/dashboard/keys).
- `DATABASE_PATH` - A path where the SQLite database will be stored. Defaults
  to `./database.sqlite`. In production this should be set to
  `$LITEFS_MOUNT_PATH/database.sqlite`.
- `LITEFS_PRIMARY_FILE` - If this environment variable is set then the
  application will only attempt to pull information from Hex and insert into the
  database if there is no file present at this path. When deployed to Fly this
  file is created by LiteFS for the node that has been elected leader, and the
  path will be `$LITEFS_MOUNT_PATH/.primary`.

## Local development

Install Gleam! See `./Dockerfile` for which version is used in production.

```shell
gleam test        # Run the tests
gleam run server  # Run the server
```

The SQL query functions are generated from the `sql` directory. To regenerate
them run `gleam run -m codegen`.

## Deployment

```shell
# Deploy the application
fly deploy
```
