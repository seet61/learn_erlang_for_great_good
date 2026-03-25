-module(ppool_serv).
-behavior(gen_server).
-export([
    start/4,
    start_link/4,
    run/2,
    sync_queue/2,
    async_queue/2,
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

%% динамический запуск наблюдаетя
-define(
    SPEC(MFA),
    {
        worker_sup,
        {ppol_worker_sup, start_link, [MFA]},
        temporary,
        10_000,
        supervisor,
        [ppool_worker_sup]
    }

).

%% описание состояние сервера
-record(
    state,
    {
        limit = undefined,
        sup = undefined,
        refs = undefined,
        queue = undefined
    }
).

%% поведенческое api
start(Name, Limit, Sup, MFA) when is_atom(Name), is_integer(Limit) ->
    gen_server:start({local, Name}, ?MODULE, {Limit, MFA, Sup}, []).

start_link(Name, Limit, Sup, MFA) when is_atom(Name), is_integer(Limit) ->
    gen_server:start_link({local, Name}, ?MODULE, {Limit, MFA, Sup}, []).

run(Name, Args) ->
    gen_server: call(Name, {run, Args}).

sync_queue(Name, Args) ->
    gen_server:call(Name, {sync, Args}, infinity).

async_queue(Name, Args) ->
    gen_server:cast(Name, {async, Args}).

stop(Name) ->
    gen_server:call(Name, stop).

%% внутереннее api обработки
init({Limit, MFA, Sup}) ->
    %% Вариант с дедлоком ожидания процессами друг друга
    %%{ok, Pid} = supervisor:start_child(Sup, ?SPEC(MFA)),
    %%link(Pid),
    %%{ok, #state{limit = Limit, sup = Sup, refs = gb_sets:empty(), queue = queue:new()}}.
    %%
    %% вариант без блокировки
    self() ! {start_worker_supervisor, Sup, MFA},
    {ok, #state{limit = Limit, sup = Sup, refs = gb_sets:empty(), queue = queue:new()}}.

handle_info({start_worker_supervisor, Sup, MFA}, State = #state{}) ->
    io:format("start_worker_supervisor ~tp ~tp ~n", [Sup, MFA]),
    {ok, Pid} = supervisor:start_child(Sup, ?SPEC(MFA)),
    io:format("ok ~tp ~n", [Pid]),
    link(Pid),
    io:format("link ~n"),
    {noreply, State#state{sup = Pid}};

handle_info({'DOWN', Ref, process, _Pid, _},
    State = #state{refs = Refs }) ->
        io:format("handle_info получили сообщение DOWN~n"),
        case gb_sets:is_element(Ref, Refs) of
            true ->
                handle_down_worker(Ref, State);
            false ->
                {noreply, State}
        end;

handle_info(Message, State) ->
    io:format("handle_info Неизвестное сообщение: ~tp~n", [Message]),
    {noreply, State}.

handle_down_worker(Ref, State = #state{limit = N, sup = Sup, refs = Refs}) ->
    case queue:out(State#state.queue) of
        {{value, {From, Args}}, Q} ->
            {ok, Pid} = supervisor:start_child(Sup, Args),
            NewRef = erlang:monitor(process, Pid),
            NewRefs = gb_sets:insert(NewRef, gb_sets:delete(Ref, Refs)),
            gen_server:reply(From, {ok, Pid}),
            {noreply, State = #state{refs = NewRefs, queue = Q}};
        {{value, Args}, Q} ->
            {ok, Pid} = supervisor:start_child(Sup, Args),
            NewRef = erlang:monitor(process, Pid),
            NewRefs = gb_sets:insert(NewRef, gb_sets:delete(Ref, Refs)),
            {noreply, State = #state{refs = NewRefs, queue =  Q}};
        {empty, _} ->
            {noreply, State = #state{limit = N+1, refs = gb_sets:delete(Ref, Refs)}}
    end.


handle_call({run, Args}, _From, State = #state{limit = N, sup = Sup, refs = Refs })
    when N > 0 ->
        io:format("handle_cast run~n"),
        {ok, Pid} = supervisor:start_child(Sup, Args),
        Ref = erlang:monitor(process, Pid),
        {reply, {ok, Pid}, State#state{limit = N-1, refs = gb_sets:add(Ref, Refs)}};

handle_call({run, _Args}, _From, State = #state{limit = N}) when N =< 0 ->
    io:format("handle_call run when limit =< 0~n"),
    {reply, noalloc, State};

handle_call({sync, Args}, _From, State = #state{limit = N, sup = Sup, refs = Refs })
    when N > 0 ->
        io:format("handle_cast sync~n"),
        {ok, Pid} = supervisor:start_child(Sup, Args),
        Ref = erlang:monitor(process, Pid),
        {reply, {ok, Pid}, State#state{limit = N-1, refs = gb_sets:add(Ref, Refs)}};

handle_call({sync, Args}, From, State = #state{queue = Q}) ->
    io:format("handle_call sync when queue~n"),
    {noreply, State#state{queue = queue:in({From, Args}, Q)}};

handle_call(stop, _From, State) ->
    io:format("handle_call stop~n"),
    {stop, normal, ok, State};

handle_call(Message, _From, State) ->
    io:format("handle_call Неизвестное сообщение: ~tp~n", [Message]),
    {noreply, State}.

handle_cast({async, Args}, State = #state{limit = N, sup = Sup, refs = Refs })
    when N > 0 ->
        io:format("handle_cast async~n"),
        {ok, Pid} = supervisor:start_child(Sup, Args),
        Ref = erlang:monitor(process, Pid),
        {reply, {ok, Pid}, State#state{limit = N-1, refs = gb_sets:add(Ref, Refs)}};

handle_cast({async, Args}, State = #state{limit = N, queue = Q}) when N =< 0 ->
    io:format("handle_cast sync when queue~n"),
    {noreply, State#state{queue = queue:in({Args}, Q)}};

handle_cast(Message, State) ->
    io:format("handle_cast Неизвестное сообщение: ~tp~n", [Message]),
    {noreply, State}.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
