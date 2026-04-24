-module(meeting).
-export([
    rent_projector/1,
    use_chairs/1,
    book_room/1,
    get_all_bookings/0,
    start/0,
    stop/0
]).
-record(bookings, {
    projector,
    chairs,
    room
}).

start() ->
    Pid = spawn(fun() -> loop(#bookings{}) end),
    register(?MODULE, Pid).

stop() ->
    ?MODULE ! stop.

rent_projector(Group) ->
    ?MODULE ! {projector, Group}.

book_room(Group) ->
    ?MODULE ! {room, Group}.

use_chairs(Group) ->
    ?MODULE ! {chairs, Group}.

get_all_bookings() ->
    Ref = make_ref(),
    ?MODULE ! {self(), Ref, get_bookings},
    receive
        {Ref, Reply} ->
            Reply
    end.

loop(Bookings = #bookings{}) ->
    receive
        stop -> ok;
        {From, Ref, get_bookings} ->
            From ! {Ref, [
                    {room, Bookings#bookings.room},
                    {chairs, Bookings#bookings.chairs},
                    {projector, Bookings#bookings.projector}
                ]},
            loop(Bookings);
        {room, Group} ->
            loop(Bookings#bookings{room = Group});
        {chairs, Group} ->
            loop(Bookings#bookings{chairs = Group});
        {projector, Group} ->
            loop(Bookings#bookings{projector = Group})
    end.
