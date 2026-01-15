-module(greeting).
-export([greet/2]).

greet(male, Name) ->
    io:format("Здравствуйте, господин ~s!", [Name]);
greet(female, Name) ->
    io:format("Здравствуйте, госпожа ~s!", [Name]);
greet(_, Name) ->
    io:format("Здравствуйте, ~s!", [Name]).
