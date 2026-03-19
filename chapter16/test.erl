-module(test).
-export([
    test1/0,
    test2/0,
    test3/0
]).

test1() ->
    curling_scoreboard_hw:reset_board(),
    curling_scoreboard_hw:set_teams("Пираты", "Шотландцы"),
    curling_scoreboard_hw:add_point("Пираты"),
    curling_scoreboard_hw:next_round().

test2() ->
    {ok, Pid} = gen_event:start_link(),
    sys:trace(Pid,true),
    gen_event:add_handler(Pid, curling_scoreboard, []),
    gen_event:notify(Pid, {set_teams, "Пираты", "Шотландцы"}),
    timer:sleep(100),
    gen_event:notify(Pid, {add_points, "Пираты", 3}),
    timer:sleep(100),
    gen_event:notify(Pid, next_round),
    timer:sleep(100),
    gen_event:delete_handler(Pid, curling_scoreboard, turn_off),
    timer:sleep(100),
    gen_event:notify(Pid, next_round),
    timer:sleep(100).

test3() ->
    {ok, Pid} = curling:start_link("Пираты", "Шотландцы"),
    curling:add_points(Pid, "Шотландцы", 2),
    curling:next_round(Pid).
