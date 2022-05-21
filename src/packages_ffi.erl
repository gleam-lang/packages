-module(packages_ffi).

-export([to_unix_timestamp/1]).

to_unix_timestamp({{Year, Month, Day}, {Hours, Minutes, Seconds}}) ->
    (calendar:datetime_to_gregorian_seconds(
        {{Year, Month, Day}, {Hours, Minutes, Seconds}}
    ) - 62167219200) * 1000000.
