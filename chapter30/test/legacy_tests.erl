-module(legacy_tests).
-export([
    test1/0
]).

test1() ->
    io:format("result1: ~tp ~n", [legacy:verify_password("iqtqts", "c81b7ba9c3adb7fa82dc2374ab679bec", "4b75f5b6de5285abcd42df4d3d7e72ef2b6cde00")]),
    io:format("result2: ~tp ~n", [legacy:verify_password("v9YrhJ", "9640172366", "f95b7e0ed30c2bec2389ec83e2bb74ed2423774f")]).
