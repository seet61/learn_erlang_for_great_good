-module(erlcount_dispatch).
-behavior(gen_fsm).
-export([
    start_link/0,
    complete/4
]).
-export([
    init/1,
    dispatching/2,
    listening/2,
    handle_sync_event/4,
    handle_info/3,
    handle_event/3,
    terminate/3,
    code_change/4
]).
-define(POOL, erlcount).
-record(data, {regex=[], refs=[]}).

%% общедоступный API
start_link() ->
    gen_fsm:start_link(?MODULE, [], []).

complete(Pid, Regex, Ref, Count) ->
    gen_fsm:send_all_state_event(Pid, {comolete, Regex, Ref, Count}).

%% внутреннее API
init([]) ->
    {ok, Re} = application:get_env(regex),
    {ok, Dir} = application:get_env(directory),
    {ok, MaxFiles} = application:get_env(max_files),
    ppool:start_pool(?POOL, MaxFiles, {erlcount_counter, start_link, []}),
    case lists:all(fun valid_regex/1, Re) of
        true ->
            self() ! {start, Dir},
            {ok, dispatching, #data{regex = [{R, 0} || R <- Re]}};
        false ->
            {stop, invalid_regex}
    end.

    valid_regex(Re) ->
        try re:run("", Re) of
            _ -> true
        catch
            error:badarg -> false
        end.

handle_info({start, Dir}, State, Data) ->
    gen_fsm:send_event(self(), erlcount_lib:find_erl(Dir)),
    {next_state, State, Data}.

dispatching({continue, File, Continuation}, Data = #data{regex = Re, refs = Refs}) ->
    F = fun({Regex, _Count}, NewRefs) ->
        Ref = make_ref(),
        ppool:async_queue(?POOL, [self(), Ref, File, Regex]),
        [Ref | NewRefs]
    end,
    NewRefs = lists:foldl(F, Refs, Ref),
    gen_fsm:send_event(self(), Continuation()),
    {next_state, dispatching, Data#data{refs = NewRefs}};

dispatching(done, Data) ->
    %%Это особый случай.Мы не можем предположить,что все
