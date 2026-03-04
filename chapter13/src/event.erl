-module(event).
-export([
    loop/1,
    normalize/1,
    loop2/1,
    start/2,
    start_link/2,
    init/3,
    cancel/1
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

start(EventName, Delay) ->
    spawn(?MODULE, init, [self(), EventName, Delay]).

start_link(EventName, Delay) ->
    spawn_link(?MODULE, init, [self(), EventName, Delay]).

%%% Внутренние функции для событий ->
init(Server, EventName, DateTime) ->
    loop2(#state{server = Server,
        name = EventName,
        to_go = time_to_go(DateTime)}).

cancel(Pid) ->
    %% Включаем монитор на случай, если другой процесс уже завершил работу
    Ref = erlang:monitor(process, Pid),
    Pid ! {self(), Ref, cancel},
    receive
        {Ref, ok} ->
            erlang:demonitor(Ref, [flush]),
            ok;
        {'DOWN', Ref, process, Pid, _Reason} ->
            ok
    end.

time_to_go(TimeOut={{_,_,_}, {_,_,_}}) ->
    Now = calendar:local_time(),
    ToGo = calendar:datetime_to_gregorian_seconds(TimeOut) -
        calendar:datetime_to_gregorian_seconds(Now),
    Secs = if ToGo > 0 -> ToGo;
              ToGo =< 0 -> 0
          end,
    normalize(Secs).
