-module(test).
-export([
    test1/0,
    test2/0,
    test3/0,
    test4/0,
    test5/0,
    test6/0,
    test7/0
]).

test1() ->
    %%  bad
    musicians:start_link(bass, bad),
    timer:sleep(5_000).

test2() ->
    musicians:start_link(bass, good),
    timer:sleep(5_000),
    musicians:stop(bass).

test3() ->
    band_supervisor:start_link(lenient).

test4() ->
    band_supervisor:start_link(angry).

test5() ->
    band_supervisor:start_link(jerk).

test6() ->
    band_supervisor:start_link(lenient),
    io:format("which_children: ~tp ~n", [supervisor:which_children(band_supervisor)]),
    supervisor:terminate_child(band_supervisor, drum),
    supervisor:terminate_child(band_supervisor, singer),
    supervisor:restart_child(band_supervisor, singer),
    io:format("count_children: ~tp ~n", [supervisor:count_children(band_supervisor)]),
    supervisor:delete_child(band_supervisor, drum),
    io:format("restart_child drum after delete: ~tp ~n", [supervisor:restart_child(band_supervisor, drum)]),
    io:format("count_children: ~tp ~n", [supervisor:count_children(band_supervisor)])
    .

test7() ->
    band_supervisor:start_link(jamband),
    supervisor:start_child(band_supervisor, [djembe, good]),
    supervisor:start_child(band_supervisor, [djembe, good]),
    supervisor:delete_child(band_supervisor, drum).
