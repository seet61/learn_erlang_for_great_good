-module(kitty_server).
-behavior(gen_server).
-export([
    start_link/0,
    order_cat/4,
    return_cat/2,
    close_shop/1
]).
%% Callbacks for `gen_server`
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2
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
    gen_server:start_link(?MODULE, [], []).

%% Синхронный вызов с ожидаением
order_cat(Pid, Name, Color, Description) ->
    gen_server:call(Pid, {order, Name, Color, Description}).

%% Асинхронный вызов
return_cat(Pid, Cat = #cat{}) ->
    gen_server:cast(Pid, {return, Cat}).

%% Синхронный вызов
close_shop(Pid) ->
    gen_server:call(Pid, terminate).

%% Функции сервера
init([]) -> {ok, []}. %% здесь не храним состояние

handle_call({order, Name, Color, Description}, _From, Cats) ->
    io:format("handle_call with params ~p, ~p, ~p~n", [Name, Color, Description]),
    if Cats =:= [] ->
            {reply, make_cat(Name, Color, Description), Cats};
       Cats =/= [] ->
            {reply, hd(Cats), tl(Cats)}
    end;

handle_call(terminate, _From, Cats) ->
    {stop, normal, ok, Cats}.

handle_cast({return, Cat = #cat{}}, Cats) ->
    {noreply, [Cat | Cats]}.

handle_info(Message, Cats) ->
    io:format("Неожиданное сообщение: ~p ~n", [Message]),
    {noreply, Cats}.

%%% Внутренние функции
make_cat(Name, Color, Description) ->
    #cat{name = Name, color = Color, description = Description}.

terminate(normal, Cats) ->
    [io:format("~p был выпущен на свободу. ~n", [Cat#cat.name]) || Cat <- Cats],
    ok.

code_change(_OldVersion, State, _Extra) ->
    %% не делаем никаких изменений
    {ok, State}.
