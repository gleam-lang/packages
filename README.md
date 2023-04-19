# Gleam Packages

📦 Search for Gleam packages on [Hex](https://hex.pm).

## Local development

Install Gleam and PostgreSQL. The application will respect the `PGUSER` and
`PGPASSWORD` environment variables, defaulting to the user `postgres` with no
password if they are not set.

A read-only API key for the Hex API should be supplied via the `HEX_API_KEY`
environment variable. You can generate one via [the Hex dashboard](https://hex.pm/dashboard/keys).

```shell
# Create the PostgreSQL databases
createdb gleam_packages
createdb gleam_packages_test

# Run the tests
gleam test

# Run the server
gleam run server
```
