-module(road).
-export([
    main/0,
    main/1
]).

main() ->
    File = "road.txt",
    {ok, Bin} = file:read_file(File),
    optimal_path(parse_map(Bin)).

main([Filename]) ->
    {ok, Bin} = file:read_file(Filename),
    Map = parse_map(Bin),
    io:format("~p~n", [optimal_path(Map)]),
    erlang:halt(0).

parse_map(Bin) when is_binary(Bin) -> parse_map(binary_to_list(Bin));
parse_map(Str) when is_list(Str) ->
    Values = [list_to_integer(X) || X <- string:tokens(Str, "\r\n\t ")],
    group_vals(Values, []).

%вытаскивание значений по 3 и группировка
group_vals([], Acc) -> lists:reverse(Acc);
group_vals([A, B, X | Rest], Acc) -> group_vals(Rest, [{A, B, X} | Acc]).

%вычисление кротчайшего шага
shortest_step({A, B, X}, {{DistA, PathA}, {DistB, PathB}}) ->
    OptA1 = {DistA + A, [{a, A} | PathA]},
    OptA2 = {DistB + B + X, [{x, X}, {b, B} | PathB]},
    OptB1 = {DistB + B, [{b, B} | PathB]},
    OptB2 = {DistA + A + X, [{b, B}, {a, A} | PathA]},
    {erlang:min(OptA1, OptA2), erlang:min(OptB1, OptB2)}.

optimal_path(Map) ->
    {A, B} = lists:foldl(fun shortest_step/2, {{0, []}, {0, []}}, Map),
    {_Dist, Path} = if hd(element(2, A)) =/= {x, 0} -> A;
                        hd(element(2, B)) =/= {x, 0} -> B
                    end,
    lists:reverse(Path).
