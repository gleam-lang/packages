-module(packages_ffi).

-export([to_gregorian_seconds/1]).

to_gregorian_seconds({{Year, Month, Day}, {Hours, Minutes, Seconds}}) ->
    calendar:datetime_to_gregorian_seconds(
        {{Year, Month, Day}, {Hours, Minutes, Seconds}}
    ).
