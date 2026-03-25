-module(test).
-export([
    test1/0
]).

test1() ->
    ppool:start_link(),
    ppool:start_pool(nagger, 2, {ppool_nagger, start_link, []}),
    ppool:run(nagger, ["Дочитать главу!", 10_000, 10, self()]),
    ppool:run(nagger, ["Посмотреть фильм", 10_000, 10, self()]),
    timer:sleep(100),
    flush(),
    ppool:run(nagger, ["Убрать в комнате", 10_000, 10, self()]),
    flush().

flush() ->
    receive Message ->
        io:format("~tp ~n", [Message]),
        flush()
    after 500 ->
        ok
    end.
