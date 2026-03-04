-module(hotload).
-export([
    server/1,
    upgrade/1
]).

server(State) ->
    receive
        update ->
            NewState = ?MODULE:upgrade(State),
            ?MODULE:server(NewState); %%переход на новую версию модуля
        _SomeMessage ->
            %% Что-то еще
            server(State) %% остается на старой версии модуля
    end.

upgrade(OldState) ->
    %% обновить и вернуть новое состояние
    ?MODULE:upgrade(OldState).
