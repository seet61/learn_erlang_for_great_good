-module(musicians).
-behavior(gen_server).
-export([
    start_link/2,
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
-record(state, {
   name = undefined,
   role = undefined,
   skill = undefined
}).
-define(DELAY, 750).

%% методы инициализации для gen_server
start_link(Role, Skill) ->
    gen_server:start_link({local, Role}, ?MODULE, [Role, Skill], []).

stop(Role) ->
    gen_server:call(Role, stop).

%% api модуля, которое будет вызываться gen_server
init([Role, Skill]) ->
    io:format("~ts init with role ~ts, skill ~ts ~n", [?MODULE, Role, Skill]),
    %% что бы узнать о смерти родительского процесса
    process_flag(trap_exit, true),

    %% устанавливает начальное значение для генератора случайных чивел на
    %% на срок жизни процесса, используя текущее время, erlang:timestamp()
    %% гарантирует всегда уникальные значения
    %% rand:seed(erlang:timestamp()),

    TimeToPlay = rand:uniform(3_000),
    Name = pick_name(),
    StringRole = atom_to_list(Role),
    io:format("Музыкант ~ts, играющий на ~ts, вошел в комнату ~n", [Name, StringRole]),
    {ok, #state{name = Name, role = StringRole, skill = Skill}, TimeToPlay}.

%% функция выбора имени персонажа
pick_name() ->
    %% Для случайных чисел надо установить начальное значение
    %% Это сделано в init/1, оттуда же и должна вызываться эта функция
    lists:nth(rand:uniform(10), firstnames())
    ++ " " ++
    lists:nth(rand:uniform(10), lastnames()).

%% имена
firstnames() ->
    ["Валери", "Арнольд", "Фиби", "Ральфи", "Карлос", "Дороти", "Киша", "Тим", "Ванда", "Джэнет"].

%% фамилии
lastnames() ->
    ["Фриззл", "Перлстейн", "Рамон", "Энн", "Франсклин", "Терес", "Теннелли", "Джамал", "Ли", "Перлстейн"].

handle_call(stop, _From, State = #state{}) ->
    io:format("~ts handle_call with stop ~n", [?MODULE]),
    {stop, normal, ok, State};

handle_call(Message, _From, State) ->
    io:format("~ts handle_call with ~tp ~n", [?MODULE, Message]),
    {noreply, State, ?DELAY}.

handle_cast(Message, State) ->
    io:format("~ts handle_cast with ~tp ~n", [?MODULE, Message]),
    {noreply, State, ?DELAY}.


handle_info(timeout, State = #state{name = Name, skill = good}) ->
    io:format("~ts handle_info with timeout for good ~n", [?MODULE]),
    io:format("~ts сыграл ноту! ~n", [Name]),
    {noreply, State, ?DELAY};
handle_info(timeout, State = #state{name = Name, skill = bad}) ->
    io:format("~ts handle_info with timeout for bad ~n", [?MODULE]),
    case rand:uniform(5) of
        1 ->
            io:format("~ts сыграл фальшиво ~n", [Name]),
            {stop, bad_note, State};
        _ ->
            io:format("~ts сыграл ноту! ~n", [Name]),
            {noreply, State, ?DELAY}
    end;
handle_info(Message, State) ->
    io:format("~ts handle_call with ~tp ~n", [?MODULE, Message]),
    {noreply, State, ?DELAY}.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(normal, State) ->
    io:format("~ts terminate with normal ~n", [?MODULE]),
    io:format("~ts покинул комнату (~ts) ~n", [State#state.name, State#state.role]);
terminate(bad_note, State) ->
    io:format("~ts terminate with bad_note ~n", [?MODULE]),
    io:format("~ts играет отстойно! изгнан из группы! (~ts) ~n", [State#state.name, State#state.role]);
terminate(shutdown, State) ->
    io:format("~ts terminate with shutdown ~n", [?MODULE]),
    io:format("Менеджер пришел вярось и уволил всю группу! "
        "~ts вернулся к концертам в подземных переходах ~n", [State#state.name]);
terminate(Reason, State) ->
    io:format("~ts terminate with ~tp ~n", [?MODULE, Reason]),
    io:format("~ts изгнан из группы! (~ts) ~n", [State#state.name, State#state.role]).
