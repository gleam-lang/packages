# Gleam Packages

📦 Search for Gleam packages on [Hex](https://hex.pm).

A Gleam application using the [Wisp](https://gleam-wisp.github.io/wisp) web framework,
served with the [Mist](https://github.com/rawhat/mist) web server, using a
Stóráil database.

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
