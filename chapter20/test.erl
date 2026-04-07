-module(test).
-export([
    test/0
]).

test() ->
    application:load(ppool),
    application:start(ppool),
    application:start(erlcount).
