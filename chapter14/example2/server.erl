-module(server).
-export([
    start/2,
    start_link/2,
    call/2,
    cast/2,
    reply/2
]).

%% Публичное API
start(Module, InitialState) ->
    spawn(fun() -> init(Module, InitialState) end).

start_link(Module, InitialState) ->
    spawn_link(fun() -> init(Module, InitialState) end).

call(Pid, Message) ->
    io:format("server call ~p with message ~p ~n", [Pid, Message]),
    Ref = erlang:monitor(process, Pid),
    Pid ! {sync, self(), Ref, Message},
    io:format("server send messge to Ref ~p ~n", [Ref]),
    receive
        {Ref, Reply} ->
            erlang:demonitor(Ref, [flush]),
            Reply;
        {'DOWN', Ref, process, Pid, Reason} ->
            erlang:error(Reason)
    after 5_000 ->
        erlang:error(timeout)
    end.

cast(Pid, Message) ->
    Pid ! {async, Message},
    ok.

reply({Pid, Ref}, Reply) ->
    io:format("server reply for pid ~p from ref ~p with ~p ~n", [Pid, Ref, Reply]),
    Pid ! {Ref, Reply}.

%% Внутренние функции
init(Module, InitialState) ->
    loop(Module, Module:init(InitialState)).

loop(Module, State) ->
    receive
        %Message -> Module:handle(Message, State)
        {async, Message} ->
            loop(Module, Module:handle_cast(Message, State));
        {sync, Pid, Ref, Message} ->
            loop(Module, Module:handle_call(Message, {Pid, Ref}, State));
        Unknown ->
            io:format("Unknown message: ~p ~n", [Unknown]),
            loop(Module, State)
    end.
