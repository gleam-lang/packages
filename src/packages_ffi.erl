-module(packages_ffi).

-export([priv_directory/1]).

priv_directory(Name) ->
    try 
      Atom = binary_to_existing_atom(Name),
      Dir = list_to_binary(code:priv_dir(Atom)),
      {ok, Dir}
    catch
      _:_ -> {error, nil}
    end.
