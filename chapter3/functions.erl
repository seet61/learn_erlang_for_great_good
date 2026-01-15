-module(functions).
-compile(export_all). % заменим потом на -export() для порядка!

head([H|_]) -> H.
second([_, X | _]) -> X.
