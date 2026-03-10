-module(kitty_server).
-export([
    start_link/0,
    order_cat/4,
    return_cat/2,
    close_shop/1
]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2
]).
-record(cat,
    {
        name,
        color = green,
        description
    }
).

%%% API для клиента
start_link() ->
    server:start_link(?MODULE, []).

%% Синхронный вызов с ожидаением
order_cat(Pid, Name, Color, Description) ->
    server:call(Pid, {order, Name, Color, Description}).

%% Асинхронный вызов
return_cat(Pid, Cat = #cat{}) ->
    server:cast(Pid, {return, Cat}).

%% Синхронный вызов
close_shop(Pid) ->
    server:call(Pid, terminate).

%% Функции сервера
init([]) -> [].

handle_call({order, Name, Color, Description}, From, Cats) ->
    io:format("handle_call with params ~p, ~p, ~p~n", [Name, Color, Description]),
    if Cats =:= [] ->
        server:reply(From, make_cat(Name, Color, Description)),
        Cats;
       Cats =/= [] ->
        server:reply(From, hd(Cats)),
        tl(Cats)
    end;

handle_call(terminate, From, Cats) ->
    server:reply(From, ok),
    terminate(Cats).

handle_cast({return, Cat = #cat{}}, Cats) ->
    [Cat | Cats].

%%% Внутренние функции
make_cat(Name, Color, Description) ->
    #cat{name = Name, color = Color, description = Description}.

terminate(Cats) ->
    [io:format("~p был выпущен на свободу. ~n", [Cat#cat.name]) || Cat <- Cats],
    exit(normal).
