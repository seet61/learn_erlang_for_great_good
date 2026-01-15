-module(functions).
%-compile(export_all). % заменим потом на -export() для порядка!
-export([head/1, second/1, same/2, valid_time/1]).

head([H|_]) -> H.
second([_, X | _]) -> X.

same(X, X) ->
    true;
same(_, _) ->
    false.

valid_time({Date = {Y, M, D}, Time = {H, Min, S}}) ->
    io:format("Кортеж даты (~p) говорит сегодня: ~p/~p/~p, ~n", [Date, Y, M, D]),
    io:format("Кортеж времени (~p) показывает: ~p:~p:~p. ~n", [Time, H, Min, S]);
valid_time(_) ->
    io:format("Перестань давать мне незнакомые данные! ~n").
