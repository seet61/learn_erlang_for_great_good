-module(erlcount_lib).
-export([
    find_erl/1
]).
-include_lib("kernel/include/file.hrl").

%% ищем все файлы имя которых заканчивается на .erl
find_erl(Directory) ->
    find_erl(Directory, queue:new()).

%% внутренние функции
%% определяем поведение в зависимости от типа файла
find_erl(Name, Queue) ->
    {ok, File = #file_info{}} = file:read_file_info(Name),
    case File#file_info.type of
        directory   -> handle_directory(Name, Queue);
        regular     -> handle_regular_file(Name, Queue);
        _Other      -> dequeue_and_run(Queue)
    end.

%% работа с содержимым директории
handle_directory(Dir, Queue) ->
    case file:list_dir(Dir) of
        {ok, []} ->
            dequeue_and_run(Queue);
        {ok, Files} ->
            dequeue_and_run(enqueue_many(Dir, Files, Queue))
    end.

%% извлеение и обработка 1 элемента
dequeue_and_run(Queue) ->
    case queue:out(Queue) of
        {empty, _} -> done;
        {{value, File}, NewQueue} -> find_erl(File, NewQueue)
    end.

%% добавляет писок элементов в очередь
enqueue_many(Path, Files, Queue) ->
    Func = fun(File, Que) -> queue:in(filename:join(Path, File), Que) end,
    lists:foldl(Func, Queue, Files).

%% проверка расширения файла
handle_regular_file(Name, Queue) ->
    case filename:extension(Name) of
        ".erl" ->
            {continue, Name, fun() -> dequeue_and_run(Queue) end};
        _NotErl ->
            dequeue_and_run(Queue)
    end.
