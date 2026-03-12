-module(trade_fsm).
-behavior(gen_fsm).

%% общедоступный API
-export([
    start/1,
    start_link/1,
    trade/2,
    accept_trade/1,
    make_offer/2,
    retract_offer/2,
    ready/1,
    cancel/1
]).

%% функции обратного вызова для gen_fsm
-export([
    init/1,
    handle_event/3,
    handle_sync_event/4,
    handle_info/3,
    terminate/3,
    code_change/4,
    %% имена состояний
    idle/2,
    idle/3,
    idle_wait/2,
    idle_wait/3,
    negotiate/2,
    negotiate/3,
    wait/2,
    ready/2,
    ready/3
]).


%% общедоступный API
start(Name) ->
    gen_fsm:start(?MODULE, [Name], []).

start_link(Name) ->
    gen_fsm:start_link(?MODULE, [Name], []).

%% запрос начала сессии
%% возвращается, когда другая сторона принимает запрос
trade(OwnPid, OtherPid) ->
    gen_fsm:sync_send_event(FsmRef, Event, Timeout).

%% примает чье-то предложение начать торговые переговоры
accept_trade(OwnPid) ->
    gen_fsm:sync_send_event(OwnPid, accept_negotiate).

%% предложение обмена
make_offer(OwnPid, Item) ->
    gen_fsm:send_event(OwnPid, {make_offer, Item}).

%% отозвать предложение обмена
retract_offer(OwnPid, Item) ->
    gen_fsm:send_event(OwnPid, {retract_offer, Item}).

%% сообщить о готовности обмена
ready(OwnPid) ->
    gen_fsm:sync_send_event(OwnPid, ready, infinity).

%% отмена сделки в любой момент
cancel(OwnPid) ->
    gen_fsm:sync_send_all_state_event(OwnPid, cancel).

%% функции обмена между КА
%% запрос обмена у другого pid
ask_negotiate(OtherPid, OwnPid) ->
    gen_fsm:send_event(OtherPid, {ask_negotiate, OwnPid}).

%% передать подтверждение о начале обмена
accept_negotiate(OtherPid, OwnPid) ->
    gen_fsm:send_event(OtherPid, {accept_negotiate, OwnPid}).

%% предложение товара
do_offer(OtherPid, Item) ->
    gen_fsm:send_event(OtherPid, {do_offer, Item}).

%% отмена предложения товара
undo_offer(OtherPid, Item) ->
    gen_fsm:send_event(OtherPid, {undo_offer, Item}).

%% запрос готовности совершить сделку
are_you_ready(OtherPid) ->
    gen_fsm:send_event(OtherPid, are_you_ready).

%% ответ о неготовности, не в состоянии wait
not_yet(OtherPid) ->
    gen_fsm:send_event(OtherPid, not_yet).

%% сообщить другому что ожидает состояние ready
%% состояние должно измениться на ready
am_ready(OtherPid) ->
    gen_fsm:send_event(OtherPid, 'ready!').

%% подтверждение готовности(ready)
ack_trans(OtherPid) ->
    gen_fsm:send_event(OtherPid, ack).

%% запрос готовности завершения сделки
ask_commit(OtherPid) ->
    gen_fsm:sync_send_event(OtherPid, ack_commit).

%% синхронное завершение сделки
do_commit(OtherPid) ->
    gen_fsm:sync_send_event(OtherPid, do_commit).

%% функции обратного вызова
-record(
    state,
    {
        name = "",          %имя игрока
        other,              %другой игрок
        own_items = [],     %наши предложенные товары
        other_items = [],   %предложение другого игрока
        monitor,            %монитор
        from                %pid отпровителя синхронного запроса
    }
).

init(Name) ->
    {ok, idle, #state{name = Name}}.

%% отправить уведомление угрокам.
%% Это зависит от реализации
%% В данном случае сообщение в консоли
notice(#state{name = Name}, String, Args) ->
    io:format("~s: " ++ String ++ "~n", [Name | Args]).

%% запись в журнал неожиданных сообщений
unexpected(Message, State) ->
    io:format("~p получено неизвестное сообщение ~p в состоянии ~p ~n",
        [self(), Message, State]).

%% события запроса обмена КА
idle({ask_negotiate, OtherPid}, State = #state{}) ->
    Ref = monitor(process, OtherPid),
    notice(State, "~p предлагает начать переговоры ~n", [OtherPid]),
    {next_state, idle_wait, State#state{other = OtherPid, monitor = Ref}};

idle(Event, Data) ->
    unexpected(Event, idle),
    {next_state, idle, Data}.

%% Клиент запрашивает КА об обмене
idle({negotiate, OtherPid}, From, State = #state{}) ->
    ask_negotiate(OtherPid, self()),
    notice(State, "предлагаем ~p начать торговые переговоры ~n", [OtherPid]),
    Ref = monitor(process, OtherPid),
    {next_state, idle_wait, State#state{other = OtherPid, monitor = Ref, from = From}};

idle(Event, _From, Data) ->
    unexpected(Event, idle),
    {next_state, idle, Data}.

%% Другая сторона предлагает торговать одновременно с нами
idle_wait({ask_negotiate, OtherPid}, State = #state{other = OtherPid}) ->
    gen_fsm:reply(State#state.from, ok),
    notice(State, "начинаем торговые переговоры ~n", []),
    {next_state, negotiate, State};
%% Другая сторона приняла наше предложение. Переходим в состояние negotiate
idle_wait({accept_negotiate, OtherPid}, State = #state{other = OtherPid}) ->
    gen_fsm:reply(State#state.from, ok),
    notice(State, "начинаем торговые переговоры ~n", []),
    {next_state, negotiate, State};

idle_wait(Event, Data) ->
    unexpected(Event, idle_wait),
    {next_state, idle_wait, Data}.

%% Клиент КА принимает предложение
idle_wait(accept_negotiate, _From, State = #state{other = OtherPid}) ->
    accept_negotiate(OtherPid, self()),
    notice(State, "начинаем торговые переговоры ~n", []),
    {next_state, negotiate, State};

idle_wait(Event, _From, Data) ->
    unexpected(Event, idle_wait),
    {next_state, idle_wait, Data}.

%% Добавляем предмет в список товаров
add(Item, Items) ->
    [Item | Items].

%% Удаляет предмет из списка товаров
remove(Item, Items) ->
    Item -- [Items].

%% Пердложение и отзыв предложенных товаров
%% предложить
negotiate({make_offer, Item}, State = #state{own_items = OwnItems}) ->
    do_offer(State#state.other, Item),
    notice(State, "предлагаю ~p ~n", [Item]),
    {next_state, negotiate, State#state{own_items = add(Item, Items)}};
%% отозвать
negotiate({retract_offer, Item}, State = #state{own_items = OwnItems}) ->
    undo_offer(State#state.other, Item),
    notice(State, "отзываю предложенный товар ~p ~n", [Item]),
    {next_state, negotiate, State#state{own_items = remove(Item, Items)}};
%% предлагают
negotiate({do_offer, Item}, State = #state{own_items = OwnItems}) ->
    notice(State, "другой ирок предлагает ~p ~n", [Item]),
    {next_state, negotiate, State#state{own_items = add(Item, Items)}};
%% отзывают предложение
negotiate({undo_offer, Item}, State = #state{own_items = OwnItems}) ->
    notice(State, "другой игрок отзывает ~p ~n", [Item]),
    {next_state, negotiate, State#state{own_items = remove(Item, Items)}};
%% проверка готовности
negotiate(are_you_ready, State = #state{other = OtherPid}) ->
    io:format("Другая сторона готова обменяться ~n"),
    notice(State,
        "Другой пользователь готов передать товары: ~n"
        "Вы почите ~p, Другая сторона получит ~p ~n",
        [State#state.other_items, State#state.own_items]),
    not_yet(OtherPid),
    {next_state, negotiate, State};
negotiate(Event, Data) ->
    unexpected(Event, negotiate),
    {next_state, negotiate, Data}.

%% запрос готовности
negotiate(ready, From, State = #state{other = OtherPid}) ->
    are_you_ready(OtherPid),
    notice(State, "спрашиваем, готова ли другая сторона, ждем ~n", []),
    {next_state, negotiate, State#state{from = From}};

negotiate(Event, _From, State) ->
    unexpected(Event, negotiate),
    {next_state, negotiate, State}.
