-module(event_server).
-export([
    init/0,
    start/0,
    start_link/0,
    terminate/0,
    subscribe/1,
    add_event/3,
    cancel/1,
    listen/1
]).
-record(state, {
   events, %%список записей #event{}
   clients %%список идентификаторов процессов
}).
-record(event, {
    name = "",
    description = "",
    pid,
    timeout = {{1970, 1, 1}, {0, 0, 0}}
}).

loop(State = #state{}) ->
    receive
        {Pid, MsgRef, {subscribe, Client}}                  ->
            Ref = erlang:monitor(process, Client),
            NewClients = orddict:store(Ref, Client, State#state.clients),
            Pid ! {MsgRef, ok},
            loop(State#state{clients = NewClients});
        {Pid, MsgRef, {add, Name, Description, TimeOut}}    ->
            case valid_datetime(TimeOut) of
                true ->
                    EventPid = event:start_link(Name, TimeOut),
                    NewEvents = orddict:store(Name,
                                                #event{
                                                    name = Name,
                                                    description = Description,
                                                    pid = EventPid,
                                                    timeout = TimeOut
                                                },
                                                State#state.events),
                    Pid ! {MsgRef, ok},
                    loop(State#state{events = NewEvents});
                false ->
                    Pid ! {MsgRef, {error, bad_timeout}},
                    loop(State)
            end;
        {Pid, MsgRef, {cancel, Name}}                       ->
            Events = case orddict:find(Name, State#state.events) of
                {ok, Event} ->
                    event:cancel(Event#event.pid),
                    orddict:erase(Name, State#state.events);
                error ->
                    State#state.events
            end,
            Pid ! {MsgRef, ok},
            loop(State#state{events = Events});
        {done, Name}                                        ->
            case orddict:find(Name, State#state.events) of
                {ok, Event} ->
                    send_to_clients({
                        done,
                        Event#event.name,
                        Event#event.description
                    },
                    State#state.clients),
                    NewEvents = orddict:erase(Name, State#state.events),
                    loop(State#state{events = NewEvents});
                error ->
                    %% Это может произойти, если мы отменили событие
                    %% и тут же наступило время его исполнения
                    loop(State)
            end;
        shutdown                                            ->
            exit(shutdown);
        {'DOWN', Ref, process, _Pid, _Reason}               ->
            loop(State#state{
                clients = orddict:erase(Ref, State#state.clients)
            });
        code_change                                         ->
            ?MODULE:loop(State);
        Unknown                                             ->
            io:format("Неизвестное сообщение: ~p~n", [Unknown]),
            loop(State)
    end.

init() ->
    %% Здесь можно загрузить список событий из файла на диске.
    %% Вам понадобится передать параметр в init, указывающий,
    %% где находится ресурс со списком событий. Затем загрузить его.
    %% Другой вариант - передать уже готовый список событий через
    %% дополнительную функцию.
    loop(#state{
        events = orddict:new(),
        clients = orddict:new()
    }).

valid_datetime({Date, Time}) ->
    try
        calendar:valid_date(Date) andalso valid_time(Time)
    catch
        error:function_clause -> %% не соответствует формату {{Г, М, Д}, {Ч, Мин, С}}
        false
    end;

valid_datetime(_) ->
    false.

valid_time({H, M, S}) -> valid_time(H, M, S).
valid_time(H, M, S) when H >= 0, H < 24,
    M >= 0, M < 60,
    S >= 0, S < 60 -> true;
valid_time(_, _, _) -> false.

send_to_clients(Msg, ClientDict) ->
    orddict:map(fun(_Ref, Pid) -> Pid ! Msg end, ClientDict).

start() ->
    register(?MODULE, Pid = spawn(?MODULE, init, [])),
    Pid.

start_link() ->
    register(?MODULE, Pid = spawn_link(?MODULE, init, [])),
    Pid.

terminate() ->
    ?MODULE ! shutdown.

subscribe(Pid) ->
    Ref = erlang:monitor(process, whereis(?MODULE)),
    ?MODULE ! {self(), Ref, {subscribe, Pid}},
    receive
        {Ref, ok} ->
            {ok, Ref};
        {'DOWN', Ref, process, _Pid, Reason} ->
            {error, Reason}
    after 5000 ->
        {error, timeout}
    end.

add_event(Name, Description, TimeOut) ->
    Ref = make_ref(),
    ?MODULE ! {self(), Ref, {add, Name, Description, TimeOut}},
    receive
        {Ref, Msg} -> Msg
    after 5000 ->
        {error, timeout}
    end.

cancel(Name) ->
    Ref = make_ref(),
    ?MODULE ! {self(), Ref, {cancel, Name}},
    receive
        {Ref, ok} -> ok
    after 5000 ->
        {error, timeout}
    end.

listen(Delay) ->
    receive
        Message = {done, _Name, _Description} ->
            [Message | listen(0)]
    after Delay * 1000 ->
        []
    end.
