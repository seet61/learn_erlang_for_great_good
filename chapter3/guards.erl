-module(guards).
-export([old_enough/1, wrong_age/1]).

old_enough(X) when X >= 16, X =< 104 -> true;
old_enough(_) -> false.

wrong_age(X) when X < 16; X > 104 ->
    true;
wrong_age(_) -> false.
