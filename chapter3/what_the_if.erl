-module(what_the_if).
-export([heh_fine/0, oh_good/1, help_me/1]).

heh_fine() ->
    if 1 =:= 1 ->
        works
    end,
    if 1 =:= 2; 1 =:= 1 ->
        works
    end,
    if 1 =:= 2; 1 =:= 1 ->
        fails
    end.

oh_good(N) ->
    if N =:= 2 -> might_succed;
       true    -> always_does % true способ написать else
    end.

%% Чисто для примера
%% ЛУчше делать через сопоставление в заголовке
help_me(Animal) ->
    Talk = if Animal == cat  -> "мяу";
              Animal == beef -> "му";
              Animal == dog  -> "гав";
              Animal == tree -> "кора дерева";
              true           -> "не понятно что"
          end,
    {Animal, "говорит " ++ Talk ++ "!"}.
