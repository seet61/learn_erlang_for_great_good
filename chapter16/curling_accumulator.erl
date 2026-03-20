-module(curling_accumulator).
-behavior(gen_event).
-export([
    init/1,
    handle_event/2,
    handle_call/2,
    handle_info/2,
    code_change/3,
    terminate/2
]).
-record(
    state,
    {
        teams = undefined,
        round = undefined
    }
).
init([]) ->
    io:format("init ~tp ~n", [#state{}]),
    {ok, #state{
        teams = orddict:new(),
        round = 0
    }}.

% обработка событий
handle_event({set_teams, TeamA, TeamB}, State = #state{teams = Teams}) ->
    io:format("curling_accumulator set_teams state: ~tp ~n", [State]),
    io:format("curling_accumulator set_teams ~ts and ~ts ~n", [TeamA, TeamB]),
    NewTeams = orddict:store(TeamA, 0, orddict:store(TeamB, 0, Teams)),
    io:format("curling_accumulator set_teams teams: ~tp ~n", [NewTeams]),
    {ok, State#state{teams = NewTeams}};

handle_event({add_points, Team, N}, State = #state{teams = Teams}) ->
    NewTeams = orddict:update_counter(Team, N, Teams),
    io:format("curling_accumulator add_points teams: ~tp ~n", [NewTeams]),
    {ok, State#state{teams = NewTeams}};

handle_event(next_round, State = #state{}) ->
    io:format("curling_accumulator next_round ~n"),
    {ok, State#state{round = State#state.round + 1}};

handle_event(_Event, State = #state{}) ->
    {ok, State}.

% обработка вызовов
handle_call(game_data, State = #state{teams = Teams, round = Round}) ->
    io:format("curling_accumulator game_data state: ~tp ~n", [State]),
    {ok, {orddict:to_list(Teams), {round, Round}}, State};

handle_call(_, State) ->
    {ok, ok, State}.

% cстандартный обработчик всего что не подошло
handle_info(_, State) ->
    {ok, State}.

code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
