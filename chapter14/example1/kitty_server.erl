%%наивная простейшая версия
-module(kitty_server).
-export([
    start_link/0,
    order_cat/4,
    return_cat/2,
    close_shop/1
]).
-record(cat,
    {
        name,
        color = green,
        description
    }
).

%%% API для клиента
start_link() ->
    spawn_link(fun init/0).

%% Синхронный вызов с ожидаением
order_cat(Pid, Name, Color, Description) ->
    Ref = erlang:monitor(process, Pid),
    Pid ! {self(), Ref, {order, Name, Color, Description}},
    receive
        {Ref, Cat} ->
            erlang:demonitor(Ref, [flush]),
            Cat;
        {'DOWN', Ref, process, Pid, Reason} ->
            erlang:error(Reason)
    after 5000 ->
        erlang:error(timeout)
    end.

%% Синхронный вызов
return_cat(Pid, Cat = #cat{}) ->
    Pid ! {return, Cat},
    ok.

%% Синхронный вызов
close_shop(Pid) ->
    Ref = erlang:monitor(process, Pid),
    Pid ! {self(), Ref, terminate},
    receive
        {Ref, ok} ->
            erlang:demonitor(Ref, [flush]),
            ok;
        {'DOWN', Ref, process, Pid, Reason} ->
            erlang:error(Reason)
    after 5000 ->
        erlang:error(timeout)
    end.

%% Функции сервера
init() -> loop([]).

loop(Cats) ->
    receive
        {Pid, Ref, {order, Name, Color, Description}} ->
            if Cats =:= [] -> % пустой и создаем новую
                Pid ! {Ref, make_cat(Name, Color, Description)},
                loop(Cats);
               Cats =/= [] -> % не пустой, берем из массива
                Pid ! {Ref, hd(Cats)},
                loop(tl(Cats))
           end;
        {return, Cat = #cat{}} ->
            loop([Cat | Cats]);
        {Pid, Ref, terminate} ->
            Pid ! {Ref, ok},
            terminate(Cats);
        Unknown ->
            %% Записать в журнал неизвестное сообщение
            io:format("Неизвестное сообщение ~p~n", [Unknown]),
            loop(Cats)
    end.

%%% Внутренние функции
make_cat(Name, Color, Description) ->
    #cat{name = Name, color = Color, description = Description}.

terminate(Cats) ->
    [io:format("~p был выпущен на свободу. ~n", [Cat#cat.name]) || Cat <- Cats],
    ok.
