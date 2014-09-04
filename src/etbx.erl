%% @author Erick Gonzalez <erick@codemonkeylabs.de>
%% @doc The ETBX library is a set of Erlang ([http://www.erlang.org]) functions to perform common tasks that are a recurrent theme during development of Erlang applications.

-module(etbx).
-vsn("1.0.0").
-export([any/2]).
-export([contains/2]).
-export([eval/1, eval/2]).
-export([get_env/1, get_env/2]).
-export([index_of/2]).
-export([index_of_any/2]).
-export([is_nil/0, is_nil/1]).
-export([maybe_apply/3, maybe_apply/4]).
-export([merge/1]).
-export([update/3]).
-export([pretty_stacktrace/0]).
-export([run/1, run/2, run/3]).
-export([set_loglevel/1]).
-export([start_app/1]).
-export([stop_app/1]).
-export([to_atom/1, to_atom/2]).
-export([to_binary/1]).
-export([to_float/1]).
-export([to_list/1]).
-export([to_rec/2]).
-export([to_string/1]).
-export([trim/1]).

%% @doc Returns one element from the list for which Pred(Elem) is not false.
%% Kinda like lists:any but instead of returning true, it returns
%% the value returned by the predicate.
any(_, []) ->
    false;
any(Pred, [H | T]) ->
    V = Pred(H),
    if V =:= false -> any(Pred, T);
       true -> V
    end.

%% @doc Same as eval(Expr, [])
-spec eval(string()) -> {ok, term(), list()} | {error, any()}.
eval(Expr) ->
    eval(Expr, []).

%% @doc Evaluates an Erlang expression
-spec eval(string(), list()) -> {ok, term(), list()} | {error, any()}.
eval(Expr0, Bindings) ->
    ExprBin0 = to_binary(Expr0),
    Len      = erlang:byte_size(ExprBin0)-1,
    ExprBin = case ExprBin0 of
                  <<_:Len/binary, $.>> -> ExprBin0;
                  Unterminated ->
                      <<Unterminated/binary, $.>>
              end,
    Expr = to_string(ExprBin),
    case erl_scan:string(Expr) of
        {ok, Scanned, _} ->
            case erl_parse:parse_exprs(Scanned) of
                {ok, Parsed} ->
                    {value, V, NBindings} = erl_eval:exprs(Parsed, Bindings),
                    {ok, V, NBindings};
                E ->
                    E
            end;
        E ->
            E
    end.

%% @doc Retrieves an Application env setting
-spec get_env(atom()) -> any().
get_env(K)->
    get_env(K, undefined).

%% @doc Retrieves a Hypervisor Application env setting
-spec get_env(atom(), any()) -> any().
get_env(K, Default) ->
    case application:get_env(K) of
        {ok, V} -> V;
        undefined -> Default
    end.

%% @doc Call the specified function if it exists, otherwise just don't and
%% return undefined
-spec maybe_apply(module(), function(), list()) -> any().
maybe_apply(Mod, Fun, Args) ->
    maybe_apply(Mod, Fun, Args, undefined).

%% @doc Call the specified function if it exists, otherwise just don't and
%% return the given Return parameter instead
-spec maybe_apply(module(), function(), list(), any()) -> any().
maybe_apply(Mod, Fun, Args, Return) ->
    try
        apply(Mod, Fun, Args)
    catch
        error:undef -> Return
    end.

%% @doc Set lager logging level at runtime. Specify one of debug, info,
%% notice, warning, error, critical, alert or emergency.
-spec set_loglevel(lager:log_level()) -> true.
set_loglevel(Level) ->
    lager:set_loglevel(lager_console_backend, Level).

%% @private
stop_apps([]) -> ok;
stop_apps([App | Apps]) ->
    lager:debug([{event, application}], "Stopping ~s~n", [App]),
    application:stop(App),
    stop_apps(Apps).

%% @private
start(App) ->
    application:start(App).

%% @private
start_dep(App, {error, {not_started, Dep}}, Apps) ->
    lager:debug([{event, application}], "Starting ~s~n", [Dep]),
    {ok, _, DApps} = start_dep(Dep, start(Dep), Apps),
    start_dep(App, start(App), DApps);
start_dep(App, {error, {already_started, App}}, Apps) ->
    {ok, App, Apps};
start_dep(App, ok, Apps) ->
    lager:debug([{event, applictation}], "~s start ok~n", [App]),
    {ok, App, [App | Apps]}.

%% @doc Starts all dependencies for a given application and then the
%% application itself. It returns an application start token that can
%% be used later to stop the application and all dependencies
-spec start_app(atom()) -> {ok, atom(), list() } | any().
start_app(App) ->
    start_dep(App, start(App), []).

%% @doc Stops an application and all its dependencies. The start token
%% that needs to be provided here is the one returned by start_app()
-spec(stop_app/1 :: ({ok, atom(), list()} | [string()]) -> ok | any()).
stop_app({ok, _, Apps}) ->
    stop_apps(Apps);
stop_app(Apps) ->
    stop_apps(Apps).

%% @doc a common sense test for what one would expect should be a 
%% "nil" value. Seriously Ericsson. 
-spec is_nil(any())  -> boolean().
is_nil(undefined) -> true;
is_nil([])        -> true;
is_nil({})        -> true;
is_nil(<<>>)      -> true;
is_nil(_)         -> false.
is_nil()          -> true.

-type recspec()::tuple().
-type proplist()::list(tuple()).

%% @private
index_of(_, [], _) -> undefined;
index_of(X, [H | T], I) ->
    if H =:= X -> I;
       true    -> index_of(X, T, I+1)
    end.

%% @doc returns the index for the first occurrence of an element in a list
%% or undefined if the element is not in the list
-spec index_of(any(), list()) -> number() | undefined.            
index_of(X, L) ->
    index_of(X, L, 0).

%% @doc returns the index for the first occurence of *any* of the elements
%% in the list provided or undefined if none of those elements is in the list
-spec index_of_any(list(), list()) -> number() | undefined.
%% @private
index_of_any([], _) ->
    undefined;
index_of_any([H | T], L) ->
    case index_of(H, L) of
        undefined ->
            index_of_any(T, L);
        I -> I
     end.                          
    
%% @doc converts a property list into a record.
-spec to_rec(recspec(), proplist()) -> record().
to_rec({R, [_ | N], Spec}, P) when is_atom(R) and is_list(Spec) ->
    list_to_tuple(
      [R | lists:foldl(
             fun ({K,V}, A) ->
                     case index_of(K, Spec) of
                         undefined -> 
                             A;
                         I -> 
                             {Head, Tail} = lists:split(I, A),
                             Rest = case Tail of
                                        [_ | M] -> M;
                                        []      -> []
                                    end,
                             Head ++ [V | Rest]
                     end
             end, N, P)]).

%% @doc Tests if X is present in the given list.
-spec contains(any(), list()) -> boolean().
contains(_, []) -> false;
contains(X, [{K,_} | T]) ->
    if X =:= K -> true;
       true    -> contains(X, T)
    end;
contains(X, [H | T]) ->
    if X =:= H -> true;
       true    -> contains(X, T)
    end.

%% @doc update property K with value V in proplist L
-spec update(any(), any(), proplist()) -> proplist().
update(K, V, []) ->
    [{K,V}];
update(K, V, [{_,_}|_] = L) ->
    [{K, V} | proplists:delete(K, L)].

%% @doc merge objects in list L. It returns a single object with
%% all the merged values. If a key is present in the list more than once,
%% the value will be that of the object found last on the list (from left
%% to right).
%% Objects can be proplists or dictionaries
-spec merge([proplist()|dict:dict()]) -> proplist() | dict:dict().
merge([{dict,_,_,_,_,_,_,_,_} | _] = L) ->
    merge(L, dict:new());
merge(L) -> 
    merge(L, []).

%% @private
merge([], A) ->
    A;
merge([[] | T], A) ->
    merge(T, A);
merge([[{_,_} | _] = H |T], A) ->
    merge(T, lists:foldl(
               fun({K,V}, AA) ->
                       update(K, V, AA)
               end,
               A, H));
merge([{dict,_,_,_,_,_,_,_,_} = H | T], A) ->
    merge(T, dict:merge(
               fun(_, _, V) ->
                       V
               end,
               A, H)).
               
%%%=========================================================================
%%% Type conversion
%%%=========================================================================

to_list(X) when is_binary(X) ->
    binary_to_list(X);
to_list(X) when is_tuple(X) ->
    IsSet = sets:is_set(X),
    if IsSet ->
        sets:to_list(X);
    true ->
        tuple_to_list(X)
    end; 
to_list(X) when is_number(X) ->
    to_string(X);
to_list(X) when is_atom(X) ->
    atom_to_list(X);
to_list(X) when is_list(X) ->
    X.
to_string(X) when is_integer(X) ->
    integer_to_list(X);
to_string(X) when is_float(X) ->
    float_to_list(X);
to_string(X) when is_binary(X) ->
    binary_to_list(X);
to_string(X) when is_atom(X) ->
    atom_to_list(X);
to_string(X) when is_list(X) ->
    X.
to_binary(X) when is_list(X) ->
    list_to_binary(X);
to_binary(X) when is_integer(X) ->
    <<X>>;
to_binary(X) when is_atom(X) ->
    atom_to_binary(X, latin1);
to_binary(X) when is_binary(X) ->
    X.
to_float(X) when is_list(X) ->
    list_to_float(X);
to_float(X) when is_integer(X) ->
    to_float(to_string(X));
to_float(X) when is_binary(X) ->
    binary_to_float(X).
to_atom(X) when is_list(X) ->
    list_to_existing_atom(X);
to_atom(X) when is_binary(X) ->
    binary_to_existing_atom(X, latin1);
to_atom(X) when is_number(X) ->
    to_atom(to_string(X));
to_atom(X) when is_atom(X) ->
    X.
to_atom(X, unsafe) when is_list(X) ->
    list_to_atom(X);
to_atom(X, unsafe) when is_binary(X) ->
    binary_to_atom(X, latin1);
to_atom(X, unsafe) when is_number(X) ->
    to_atom(to_string(X), unsafe);
to_atom(X, unsafe) when is_atom(X) ->
    X.

%%%=========================================================================
%%% Running Shell Commands
%%%=========================================================================

run(Cmd) ->
    run(Cmd, noinput, 5000).

run(Cmd, Timeout) when is_number(Timeout) ->
    run(Cmd, noinput, Timeout);
run(Cmd, Input) when is_list(Input) ->
    run(Cmd, Input, 5000).

run(Cmd, Input, Timeout) ->
    Port = open_port({spawn, Cmd}, [exit_status]),
    if Input =/= noinput ->
       Port ! {self(), {command, Input}};
       true ->
            ok
    end,
    run_loop(Port, <<>>, Timeout).

run_loop(Port, Data, Timeout) ->
    receive {Port, {data, NewData}}  -> 
                NewBin = to_binary(NewData),
                run_loop(Port, <<Data/binary,NewBin/binary>>, Timeout);
            {Port, {exit_status, 0}} -> {ok, Data};
            {Port, {exit_status, S}} -> {error, S}
    after Timeout 
              -> throw(timeout)
    end.

pretty_stacktrace() ->
    T = erl_syntax:abstract(erlang:get_stacktrace()),
    erl_prettypr:format(T).

trim(<<Bin/binary>>) ->
    re:replace(Bin, "^\\s+|\\s+$", "", [{return, binary}, global]);
trim(List) when is_list(List) ->
    string:strip(List, both, $ ).
