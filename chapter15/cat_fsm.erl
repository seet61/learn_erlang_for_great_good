-module(cat_fsm).
-export([
    start/0,
    event/2,
    test/0
]).

start() ->
    spawn(fun() -> dont_give_crap() end).

event(Pid, Event) ->
    Ref = make_ref(), %% не заботимся о мониторах в этом примере
    Pid ! {self(), Ref, Event},
    receive
        {Ref, Message} -> {ok, Message}
    after 5_000 ->
        {error, timeout}
    end.

dont_give_crap() ->
    receive
        {Pid, Ref, _Message} -> Pid ! {Ref, meh};
        _ -> ok
    end,
    io:format("Переключаюсь в состояние 'dont_give_crap' ~n"),
    dont_give_crap().

test() ->
    Cat = cat_fsm:start(),
    cat_fsm:event(Cat, pet),
    cat_fsm:event(Cat, love),
    cat_fsm:event(Cat, cherish).
