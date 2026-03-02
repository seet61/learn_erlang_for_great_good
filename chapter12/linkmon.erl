-module(linkmon).
-export([
    myproc/0,
    chain/1,
    start_critic/0,
    judge/3,
    critic/0,
    start_critic2/0,
    restarter/0,
    judge2/2,
    critic2/0
]).

myproc() ->
    timer:sleep(5000),
    exit(reason).

chain(0) ->
    receive
        _ -> ok
    after 2000 ->
        exit("цепочка обрывается")
    end;
chain(N) ->
    Pid = spawn(fun() -> chain(N - 1) end),
    link(Pid),
    receive
        _ -> ok
    end.

start_critic() ->
    spawn(?MODULE, critic, []).

judge(Pid, Band, Album) ->
    Pid ! {self(), {Band, Album}},
    receive
        {Pid, Criticism} -> Criticism
    after 2000 ->
        timeout
    end.

critic() ->
    receive
        {From, {"Rage Against the Turing Machine", "Unit Testify"}} ->
            From ! {self(), "Они замечательны!"};
        {From, {"System of a Downtime", "Memoize"}} ->
            From ! {self(), "Это, конечно, не Johny Cash, но они хороши."};
        {From, {"Johny Cash", "The Token Ring of Fire"}} ->
            From ! {self(), "Просто невероятно."};
        {From, {_Band, _Album}} ->
            From ! {self(), "Ужасное исполнение!"}
    end,
    critic().

start_critic2() ->
    spawn(?MODULE, restarter, []).

restarter() ->
    process_flag(trap_exit, true),
    Pid = spawn_link(?MODULE, critic2, []),
    register(critic, Pid),
    receive
        {'EXIT', Pid, normal}   -> ok; % не авария
        {'EXIT', Pid, shutdown}   -> ok; % не авария, ручное завершение
        {'EXIT', Pid, _}   -> restarter()
    end.

judge2(Band, Album) ->
    Ref = make_ref(),
    critic ! {self(), Ref, {Band, Album}},
    receive
        {Ref, Criticism} -> Criticism
    after 2000 ->
        timeout
    end.

critic2() ->
    receive
        {From, Ref, {"Rage Against the Turing Machine", "Unit Testify"}} ->
            From ! {Ref, "Они замечательны!"};
        {From, Ref, {"System of a Downtime", "Memoize"}} ->
            From ! {Ref, "Это, конечно, не Johny Cash, но они хороши."};
        {From, Ref, {"Johny Cash", "The Token Ring of Fire"}} ->
            From ! {Ref, "Просто невероятно."};
        {From, Ref, {_Band, _Album}} ->
            From ! {Ref, "Ужасное исполнение!"}
    end,
    critic2().
