-module(m8ball).
-behavior(application).
%% методы обратного вызова
-export([
    start/2,
    stop/1
]).
%% интерфейс
-export([
    ask/1
]).

%% методы обратного вызова
start(normal, []) ->
    m8ball_sup:start_link();

start({takeover, _OtherNode}, []) ->
    m8ball_sup:start_link().

stop(_State) ->
    ok.

%% интерфейс
ask(Question) ->
    m8ball_server:ask(Question).
