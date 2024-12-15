-module(ethos_ffi).
-export([
    bag_new/0, bag_get/2, bag_insert/3, bag_delete/3, drop/1,
    bag_delete_value/2, bag_delete_key/2
]).

bag_new() ->
    ets:new(ethos_table, [bag, public]).

bag_get(Bag, Key) ->
    Items1 = ets:lookup(Bag, Key),
    Items2 = lists:map(fun(Elem) -> element(2, Elem) end, Items1),
    {ok, Items2}.

bag_insert(Bag, Key, Value) ->
    ets:insert(Bag, {Key, Value}),
    {ok, nil}.

bag_delete(Bag, Key, Value) ->
    ets:delete_object(Bag, {Key, Value}),
    {ok, nil}.

bag_delete_key(Bag, Key) ->
    ets:delete(Bag, Key),
    {ok, nil}.

bag_delete_value(Bag, Value) ->
    MatchSpec = {{'$1', Value}, [], ['$1']},
    Keys = ets:select(Bag, [MatchSpec]),
    {ok, Keys}.

drop(Table) ->
    ets:delete(Table),
    nil.
