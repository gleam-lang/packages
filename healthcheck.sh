#!/bin/sh

exec wget --spider --quiet "http://127.0.0.1:3000/?search=healthcheck"
