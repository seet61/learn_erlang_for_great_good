-module(ppool_supersup).
-export([
    start_link/0,
    stop/0,
    start_pool/3,
    stop_pool/1
]).
-export([
    init/1
]).

start_link() ->
    supervisor:start_link({local, ppool}, ?MODULE, []).

%% остановка наблюдателя через kill
stop() ->
    case whereis(ppool) of
        Pid when is_pid(Pid) ->
            exit(Pid, kill);
        _ -> ok
    end.

init([]) ->
    MaxRestart = 6,
    MaxTime = 3600,
    {ok, {{one_for_one, MaxRestart, MaxTime}, []}}.

start_pool(Name, Limit, MFA) ->
    ChildSpec = {Name,
        {ppool_sup, start_link, [Name, Limit, MFA]},
        permanent, 10_500, supervisor, [ppool_sup]
    },
    io:format("start_pool with ChildSpec: ~tp ~n", [ChildSpec]),
    supervisor:start_child(ppool, ChildSpec).

stop_pool(Name) ->
    supervisor:terminate_child(ppool, Name),
    supervisor:delete_child(ppool, Name).
