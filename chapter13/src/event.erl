-module(event).
-export([
    loop/1,
    normalize/1,
    loop2/1
]).
-record(state, {
   server,
   name = "",
   to_go = 0
}).

loop(State = # state{server = Server}) ->
    receive
        {Server, Ref, cancel} ->
            Server ! {Ref, ok}
    after State#state.to_go * 1_000 ->
        Server ! {done, State#state.name}
    end.

%% Поскольку ожидание таймера в Erlang ограничено интервалом в 49 дней
%% 49 * 24 * 60 * 60 * 1_000 в миллисекундах, мы используем функцию:
normalize(N) ->
    Limit = 49 * 24 * 60 * 60,
    [N rem Limit | lists:duplicate(N div Limit, Limit)].

loop2(State = #state{server = Server, to_go = [T | Next]}) ->
    receive
        {Server, Ref, cancel} ->
            Server ! {Ref, ok}
    after T * 1_000 ->
        if Next =:= [] ->
            Server ! {done, State#state.name};
        Next =/= []->
            loop(State#state{to_go = Next})
        end
    end.
