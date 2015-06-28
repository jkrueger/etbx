%% @author Erick Gonzalez <erick@codemonkeylabs.de>
%% @doc The ETBX library is a set of Erlang ([http://www.erlang.org]) functions to perform common tasks that are a recurrent theme during development of Erlang applications.

-module(etbx).
-vsn("1.0.0").

-export([any/2]).
-export([contains/2]).
-export([delete/2]).
-export([doall/1]).
-export([eval/1, eval/2]).
-export([expand/2, expand/3]).
-export([first/1]).
-export([get_env/1, get_env/2]).
-export([get_in/3]).
-export([get_value/2, get_value/3]).
-export([index_of/2]).
-export([index_of_any/2]).
-export([is_nil/0, is_nil/1]).
-export([maybe_apply/3, maybe_apply/4]).
-export([merge/1]).
-export([merge_with/2]).
-export([pad/3]).
-export([partition/2]).
-export([pretty_stacktrace/0]).
-export([remap/2]).
-export([range/0, range/1, range/2, range/3]).
-export([run/1, run/2, run/3]).
-export([select/2]).
-export([set_loglevel/1]).
-export([seq/1, seq/2]).
-export([split/2]).
-export([start_app/1]).
-export([stop_app/1]).
-export([take/2]).
-export([to_atom/1, to_atom/2]).
-export([to_binary/1]).
-export([to_float/1]).
-export([to_hex/1]).
-export([to_list/1]).
-export([to_rec/2]).
-export([to_string/1]).
-export([to_tuple/1]).
-export([trim/1]).
-export([update/3]).

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

%% @doc returns the first element of the specified list, tuple or binary
-spec first(list() | tuple() | binary()) -> any().
first(<<E, _/binary>>) ->
    E;
first([E | _]) ->
    E;
first(T) when is_tuple(T) ->
    element(1, T);
first(_) ->
    throw(badarg).
    
%% @doc converts a property list into a record.
-spec to_rec(recspec(), proplist()) -> record().
to_rec({R, [_ | N], Spec}, P) when is_atom(R) and is_list(Spec) ->
    list_to_tuple(
      [R | lists:foldl(
             fun ({K,V}, A) ->
                     case index_of(etbx:to_atom(K, unsafe), Spec) of
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

%% @doc update property K with value V in an associate structure
-spec update(any(), any(), proplist() | map()) -> proplist() | map().
update(K, V, []) ->
    [{K,V}];
update(K, V, [{_,_}|_] = L) ->
    [{K, V} | proplists:delete(K, L)];
update(K, V, {L}) when is_list(L) ->
    {update(K, V, L)};
update(K, V, M) when is_map(M) ->
    maps:put(K, V, M).

%% @doc delete property K from associative structure
-spec delete(any(), proplist() | map()) -> proplist() | map().
delete(_, []) ->
    [];
delete(K, [{_, _} | _] = L) ->
    proplists:delete(K, L);
delete(K, {L}) when is_list(L) ->
    {delete(K, L)};
delete(K, M) when is_map(M) ->
    maps:remove(K, M).

%% @doc merge objects in list L. It returns a single object with
%% all the merged values. If a key is present in the list more than once,
%% the value will be that of the object found last on the list (from left
%% to right).
%% Objects can be proplists or dictionaries
-spec merge([proplist()|dict:dict()]) -> proplist() | dict:dict().
merge([{dict,_,_,_,_,_,_,_,_} | _] = L) ->
    merge_with(fun(_, _, V) -> V end, L);
merge(L) -> 
    merge(L, []).

%% @private
merge([], A) ->
    A;
merge([undefined | T], A) ->
    merge(T, A);
merge([[] | T], A) ->
    merge(T, A);
merge([H | T], A) ->
    merge(T, merge_properties(H, A)).

merge_properties({H}, {A}) ->
    {merge_properties(H, A)};
merge_properties({H}, A) ->
    {merge_properties(H, A)};
merge_properties(H, A) ->
    lists:foldl(
      fun({K,V}, AA) ->
              update(K, V, AA)
      end,
      A, H).

merge_with(F, [{dict,_,_,_,_,_,_,_,_} | _] = L) ->
    merge_with(F, L, dict:new());
merge_with(F, L) ->
    merge_with(F, L, []).

merge_with(_, [], A) ->
    A;
merge_with(F, [undefined | T], A) ->
    merge_with(F, T, A);
merge_with(F, [[] | T], A) ->
    merge_with(F, T, A);
merge_with(F, [[{_,_} | _] = L | T], A) ->
    merge_with(
      F, T, 
      lists:foldl(
        fun({K, V}, S) ->
            update(
              K,
              case get_value(K, S) of
                  undefined -> V;
                  V2 ->        F(K, V, V2)
              end,
              S)
        end,
        A, L));
merge_with(F, [{dict,_,_,_,_,_,_,_,_} = D | T], A) ->
    merge_with(F, T, dict:merge(F, D, A)).

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

to_tuple(X) when is_list(X) ->
    list_to_tuple(X).

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
    Trace = erlang:get_stacktrace(),
    try
        T = erl_syntax:abstract(Trace),
        erl_prettypr:format(T)
    catch
        error:_ ->
            io_lib:format("~p", [Trace])
    end.

trim(<<Bin/binary>>) ->
    re:replace(Bin, "^\\s+|\\s+$", "", [{return, binary}, global]);
trim(List) when is_list(List) ->
    string:strip(List, both, $ ).

%% @doc same as get_value(K, O, undefined)
-spec get_value(any(), map() | proplist()) -> any() | undefined.
get_value(K, O) ->
    get_value(K, O, undefined).

%% @doc looks up key in an associative structure. If no value for that key
%% is found, it returns the passed in default parameter
-spec get_value(any(), map() | proplist(), any()) -> any().
get_value(K, O, D) when is_map(O) ->
    maps:get(K, O, D);
get_value(K, O, D) when is_list(O) ->
    proplists:get_value(K, O, D);
get_value(K, {O}, D) when is_list(O) -> 
    proplists:get_value(K, O, D);
get_value(_, _, D) ->
    D.

%% @doc Recursively look up a value in an associative structure
get_in([], D, D) ->
    D;
get_in([], O, _) ->
    O;
get_in([K | KS], O, D) ->
    get_in(KS, get_value(K, O, D), D);
get_in(K, O, D) ->
    get_value(K, O, D).

%% @doc returns an associative structure of the same passed in type containing
%% only key/value pairs for keys present in the list provided
-spec select(map() | proplist(), list()) -> map() | proplist.
select(O, L) when is_map(O) ->
    lists:foldl(
      fun(K, A) -> 
              try
                  maps:put(K, maps:get(K, O), A)
              catch 
                  error:bad_key ->
                      A
              end
      end,
      #{}, L);
select(O, L) when is_list(O) ->
    lists:foldl(
      fun(K, A) ->
              case proplists:get_value(K, O, '_etbx_no_value_') of
                  '_etbx_no_value_' ->
                      A;
                  V ->
                      update(K, V, A)
              end
      end, [], L);
select(_, _) ->
    throw (badarg).

%% @doc given a function F and a property list P, apply F to the values of the
%% property list possibly recursing into nested property lists.
-spec remap(fun(), proplist()) -> proplist().
remap(F, [{_,_} | _] = P) ->
    lists:map(
      fun({K, V}) ->
              {K, remap(F, V)}
      end,
      P);
remap(F, V) ->
    F(V).

%% @doc same as expand(M, T, 10)
-spec expand(proplist() | map(), any()) -> any().
expand(M, T) ->
    expand(M, T, 10).

%% @doc given an associative structure M any term T and an integer N, 
%% it expands up to N times recursively all terms found in T which map to an
%% expression in M. 
-spec expand(proplist() | map(), any(), integer()) -> any().
expand(_, T, 0) ->
    throw({too_many_expansions, T});
expand(M, T, N) when is_list(T) ->
    [ expand(M, X, N) || X <- T ];
expand(M, T, N) when is_tuple(T) ->
    to_tuple(expand(M, to_list(T), N));
expand(M, T, N) ->
    case get_value(T, M, '_n/a_') of
        '_n/a_' ->
            T;
        NT ->
            expand(M, NT, N-1)
    end.

%% @doc basically lists:split without the mental retardation.
-spec split(integer(), list()) -> {list(), list()}.
split(0, {L1, L2}) ->
    {lists:reverse(L1), L2};
split(_, {L1, []}) ->
    {lists:reverse(L1), []};
split(N, {L1, [H | T]}) ->
    split(N-1, {[H | L1], T});
split(N, L) when is_list(L) ->
    split(N, {[], L}).

%% @doc Split a list into multiple lists of n items each. The last partition
%% will contain less than n elements if the length of the list is not a multiple
%% of n
-spec partition(integer(), list()) -> [list()].
partition(0, _) ->
    [];
partition(N, L) ->
    partition(N, L, []).

partition(_, [], A) ->
    lists:reverse(A);
partition(N, L, A) ->
    { P, Rest} = split(N, L),
    partition(N, Rest, [P | A]).

%% @doc if the length of the list L is less than N, pad the list
%% with the provided padding term P
-spec pad(integer(), list(), any()) -> list().
pad(N, L, P) when length(L) < N ->
    pad(N, reverse, lists:reverse(L), P);
pad(_, L, _)  ->
    L.

pad(N, reverse, L, P) when length(L) < N ->
    pad(N, reverse, [P | L], P);
pad(_, reverse, L, _) ->
    lists:reverse(L).

to_hex(Bits) ->
    Token     = << << (integer_to_binary(X,16))/binary>> || <<X:4>> <= Bits >>,
    string:to_lower(etbx:to_list(Token)).

%%%=========================================================================
%%% (Lazy) sequences
%%%=========================================================================

seq(List) when is_list(List) ->
    List.

seq(Generator, State) ->
    {Generator, State}.

take(N, Seq) ->
    take(N, Seq, []).

take(N, Seq, Acc) when N=:=0 orelse Seq=:=[] ->
    lists:reverse(Acc);
take(N, [H|T], Acc) ->
    take(N-1, T, [H | Acc]);
take(N, {Generator, State}, Acc) when is_function(Generator) ->
    {Value, NState} = Generator(State),
    {Seq, NAcc} = case Value of
                      undefined ->
                          {[], Acc};
                      _ ->
                          {{Generator, NState}, [Value|Acc]}
                  end,
    take(N-1, Seq, NAcc).

range() ->
    range(0).
    
range(Min) ->
    {fun(Last) -> {Last, Last + 1} end, Min}.

range(Min, Max) when is_integer(Min), is_integer(Max) ->
    range(Min, Max, 1).

range(Min, Max, Step) when is_integer(Min), is_integer(Max), is_integer(Step) -> 
    {fun(Last) when Last >= Max -> {undefined, Last};
      (Last) -> {Last, Last+Step}
     end, Min}.

doall(Seq) ->
    doall(Seq, []).

doall([], Acc) ->
    lists:reverse(Acc);
doall(List, []) when is_list(List) ->
    doall([], List);
doall({Generator, State}, Acc) ->
    {Value, NState} = Generator(State),
    {Seq, NAcc} = case Value of
                      undefined ->
                          {[], Acc};
                        _ ->
                          {{Generator, NState}, [Value | Acc]}
                  end,
    doall(Seq, NAcc).
