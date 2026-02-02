-module(exceptions).
-export([
    throws/1,
    errors/1,
    exits/1,
    sword/1,
    black_knight/1,
    talk/0
]).

throws(F) ->
    try F() of
        _ -> ok
    catch
        Throw -> {throw, caught, Throw}
    end.


errors(F) ->
    try F() of
        _ -> ok
    catch
        error:Error -> {error, caught, Error}
    end.

exits(F) ->
    try F() of
        _ -> ok
    catch
        exit:Exit -> {exit, caught, Exit}
    end.

sword(1) -> throw(slice);   %резать
sword(2) -> erlang:error(cur_arm);   %рубить руку
sword(3) -> exit(cut_leg);   %рубить ногу
sword(4) -> throw(punch);   %ударить
sword(5) -> exit(cross_bridge). %перейти мост

black_knight(Attack) when is_function(Attack, 0) ->
    try Attack() of
        _               -> "Никто не пройдет!"
    catch
        throw:slice     -> "Это просто царапина!";
        error:cut_arm   -> "Бывало и похуже.";
        exit:cut_leg    -> "Ну давай, слабак!";
        _ : _           -> "Просто легкая рана."
    end.

talk() -> "blah blah".
