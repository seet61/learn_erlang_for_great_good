-module(curling_scoreboard_hw).
-export([
    add_point/1,
    next_round/0,
    set_teams/2,
    reset_board/0
]).

%% это модуль имитации поведения контроллера, с простым функционалом вывода счета и команд

%% показывает команды на табло
set_teams(TeamA, TeamB) ->
    io:format("Ход игры: команда ~ts против ~ts ~n", [TeamA, TeamB]).

%% переключение раунда
next_round() ->
    io:format("Ход игры: конец раунда ~n").

%% добавить очко команде
add_point(Team) ->
    io:format("Ход игры: очки команды ~ts увеличены на 1 ~n", [Team]).

%% сброс состояния
reset_board() ->
    io:format("Ход игры: все команды сброшены и очки обнулены ~n").
