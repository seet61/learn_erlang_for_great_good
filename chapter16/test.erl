-module(test).
-export([
    test1/0,
    test2/0,
    test3/0,
    test4/0,
    test5/0,
    test6/0
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

test4() ->
    {ok, Pid} = curling:start_link("Пираты", "Шотландцы"),
    HandlerId = curling:join_feed(Pid, self()),
    curling:add_points(Pid, "Шотландцы", 2),
    flush(),
    curling:leave_feed(Pid, HandlerId),
    curling:next_round(Pid),
    flush().

flush() ->
    receive Message ->
        io:format("test4: ~tp ~n", [Message]),
        flush()
    after 500 ->
        ok
    end.

test5() ->
    {ok, Pid} = gen_event:start_link(),
    sys:trace(Pid, true),
    gen_event:add_handler(Pid, curling_accumulator, []),
    gen_event:notify(Pid, {set_teams, "Пираты", "Шотландцы"}),
    timer:sleep(100),
    gen_event:notify(Pid, {add_points, "Пираты", 3}),
    timer:sleep(100),
    gen_event:notify(Pid, next_round),
    timer:sleep(100),
    gen_event:delete_handler(Pid, curling_accumulator, turn_off),
    timer:sleep(100),
    gen_event:notify(Pid, next_round),
    timer:sleep(100).

test6() ->
    {ok, Pid} = curling:start_link("Пираты", "Шотландцы"),
    curling:add_points(Pid, "Шотландцы", 2),
    curling:next_round(Pid),
    curling:add_points(Pid, "Пираты", 3),
    curling:next_round(Pid).
    %%io:format("game_info: ~tp ~n", [curling:game_info(Pid)]).
