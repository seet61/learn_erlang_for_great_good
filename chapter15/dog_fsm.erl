-module(dog_fsm).
-export([
    start/0,
    squirrel/1,
    pet/1,
    test/0
]).

start() ->
    spawn(fun() -> bark() end).

squirrel(Pid) ->
    Pid ! squirrel.

pet(Pid) ->
    Pid ! pet.

bark() ->
    io:format("Собака говорит: ГАВ! ГАВ! ~n"),
    receive
        pet ->
            wag_tail();
        _ ->
            io:format("Собака в смущении ~n"),
            bark()
    after 2_000 ->
        bark()
    end.

wag_tail() ->
    io:format("Собака виляет хвостом ~n"),
    receive
        pet ->
            sit();
        _ ->
            io:format("Собака в смущении ~n"),
            wag_tail()
    after 30_000 ->
        bark()
    end.

sit() ->
    io:format("Собака сидит. Хороший пес ~n"),
    receive
    squirrel ->
            bark();
        _ ->
            io:format("Собака в смущении ~n"),
            sit()
    end.

test() ->
    Pid = dog_fsm:start(),
    dog_fsm:pet(Pid),
    dog_fsm:pet(Pid),
    dog_fsm:pet(Pid),
    dog_fsm:squirrel(Pid),
    dog_fsm:pet(Pid),
    timer:sleep(30_000),
    dog_fsm:pet(Pid),
    dog_fsm:pet(Pid).
