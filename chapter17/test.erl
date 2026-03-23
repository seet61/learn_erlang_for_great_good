-module(test).
-export([
    test1/0,
    test2/0,
    test3/0,
    test4/0,
    test5/0
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
