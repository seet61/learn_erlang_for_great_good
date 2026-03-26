%% Демонстративный модуль, надоедалка, напоминающий о задачах.
%% новый вариант усовершенствованный, по сравнению со старой задачей
-module(ppool_nagger).
-behavior(gen_server).
-export([
    start_link/4,
    stop/1
]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    code_change/3,
    terminate/2
]).

start_link(Task, Delay, Max, SendTo) ->
    io:format("start_link with params"),
    gen_server:start_link(?MODULE, {Task, Delay, Max, SendTo}, []).

stop(Pid) ->
    gen_server:call(Pid, stop).

%% функции обратного вызова gen_server для OTP
init({Task, Delay, Max, SendTo}) ->
    process_flag(trap_exit, true), % for tests & terminate too
    {ok, {Task, Delay, Max, SendTo}, Delay}.

handle_call(stop, _From, State) ->
    {stop, normal, ok, State};

handle_call(_Message, _From, State) ->
    {noreply, State}.

handle_cast(_Message, State) ->
    {noreply, State}.

handle_info(timeout, {Task, Delay, Max, SendTo}) ->
    SendTo ! {self(), Task},
    if Max =:= infinity ->
        {noreply, {Task, Delay, Max, SendTo}, Delay};
       Max =< 1 ->
        {stop, normal, {Task, Delay, Max, SendTo}};
       Max > 1 ->
        {noreply, {Task, Delay, Max, SendTo}, Delay}
     end.

%% Не можем использовать handle_info ниже
%% если это случится, то мы отменим отчест таймаутов и превратим процесс в зомби
%% лучще аварийно завершиться
%% handle_info(Message, State) ->
%%    io:format("handle_info Неизвестное сообщение: ~tp~n", [Message]),
%%    {noreply, State}.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
