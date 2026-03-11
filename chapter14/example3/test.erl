-module(test).
-export([
    cats/0
]).

cats() ->
    {ok, Pid} = kitty_server:start_link(),
    io:format("process started with ~p~n", [Pid]),
    Cat1 = kitty_server:order_cat(Pid, carl, brow, "test"),
    io:format("Cat1: ~p~n", [Cat1]),
    kitty_server:return_cat(Pid, Cat1),
    io:format("return_cat: ~p~n", [Cat1]),
    Cat2 = kitty_server:order_cat(Pid, jimmy, orange, "test2"),
    io:format("Cat2: ~p~n", [Cat2]),
    Cat3 = kitty_server:order_cat(Pid, jimmy, orange, "test2"),
    io:format("Cat3: ~p~n", [Cat3]),
    kitty_server:return_cat(Pid, Cat1),
    io:format("return_cat: ~p~n", [Cat1]),
    kitty_server:close_shop(Pid),
    io:format("close_shop~n").
