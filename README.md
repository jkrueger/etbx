# Overview

The ETBX library is a set of [Erlang](http://www.erlang.org) functions to perform common tasks that are a recurrent theme during development of Erlang applications.

## Building

    $ rebar compile

## Documentation
Use the Source Luke!

run:

    $ rebar doc
    
## Managing Applications:
### etbx:start_app/1 - Starting Erlang applications.
Starting applications and their dependencies during development can be a pain. So, use: `Apps = etbx:start_app(my_app).` to start all dependencies and my_app itself. To stop all applications started this way just do `etbx:stop_app(Apps).`, where `Apps` is bound to the value returned previously by `etbx:start_app().`
## Funs
### etbx:maybe_apply/{3,4} - Calling functions that might not be defined.
If you need to use hooks, which a module might or might not implement, use `etbx:maybe_apply(Module, Function, Args[, Default]).`. If `Function` is not present in `Module`, this call will return `Default`.
## Working with values and types

### etbx:any/2
`etbx:any(Pred, List)` Returns one element from the list for which Pred(Elem) is not false. Kinda like lists:any but instead of returning true, it returns the value returned by the predicate.

### etbx:contains/2
`etbx:contains(Element, List)` Tests if a given element is present in a list.

### etbx:is_nil - Sensible null checks
When facing a practical implementation, often one just wants code to behave in an obvious manner. That is, regardless of whether it is academically correct to consider an empty string or list as a "nil" value, being able to just write expressive code that does what one in 99% of cases would expect is simply a Good Thing (tm). For example, instead of polluting your code with expressions like `Str == "" or Str == undefined`, one can write `etbx:is_nil(Str)` instead.

### etbx:index_of/2
It baffles me why would this not be part of the lists module. `etbx:index_of(Element, List)` performs a linear search of the given list and returns the index at which a given element can be found if at all. If not present, returns `not_found`.

### etbx:to_atom/{1,2}, etbx:to_binary/1, etbx:to_list/1, etbx:to_string/1
Conversion utility functions.. when you just don't want to write guards for everything. Just take something and make it the type you want. Done. For atoms, the optional "unsafe" parameter can be specified when you want to say explicitly that dynamic creation of atom is ok and you have thought of the ramifications.
### etbx:to_rec/2
During my normal development I kept running into this one: how do you build a record from a property list?. One can write a one liner with a list comprehension to roll a simple solution which IMHO is incomplete, since one wants to respect default record values and ignore extra properties in the list, etc. So, this helper function does just that. For example:
```
-record(frob, {foo, bar="bar", baz}).
etbx:to_rec(?RECSPEC(frob), [{baz, "baz"}, {foo, "foo"}])
```
which yields `#frob{foo="foo", bar="bar", baz="baz"}`

### etbx:merge/1
`etbx:merge(List)` Merges elements of the list. Right now it is for proplists and dicts.. so it will return a single object with all the keys from all the objects in List. Note that objects to the right take precedence over objects on the left.
### etbx:update/3
`etbx:update(K, V, Proplist)` "Replaces" an entry for K in a proplist with the given value. If the entry doesn't exist, it is added to the proplist.

## Interacting with the system
### etbx:run/{1,2,3} - Running system commands
Seriously sometimes you just want to execute a shell command without having to write a neural network for the interprocess communication. `etbx:run(Command, Input, Timeout)` does just that. It runs "Command" feeding it the data specified on Input via its stdin and waits a maximum of "Timeout" milliseconds before giving up on the spawned program. Simple. Timeout and Input are optional values.
