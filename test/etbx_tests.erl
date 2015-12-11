-module(etbx_tests).
-include("etbx.hrl").
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).
-record(frob, {foo, bar="bar", baz}).

foo() ->
    foo.

maybe_apply_test_() ->
    [?_assertEqual(foo,       etbx:maybe_apply(?MODULE, foo, [])),
     ?_assertEqual(undefined, etbx:maybe_apply(?MODULE, bar, []))].

maybe_apply_4_test_() ->
    [{"failing case - builtin call",
      ?_assertNotEqual(default,etbx:maybe_apply(math, cos, [1], default))
     },
     {"default for undef function",
      ?_assertEqual(default,   etbx:maybe_apply(?MODULE, bar, [], default))
     },
     {"result for defined function",
      ?_assertEqual(foo,       etbx:maybe_apply(?MODULE, foo, [], default))
     },
     {"builtin call",
      ?_assertEqual(2,         etbx:maybe_apply(erlang, length, [[1,2]]))
     }
    ].

is_nil_test_() ->
    [?_assert(etbx:is_nil("")),
     ?_assert(etbx:is_nil([])),
     ?_assert(etbx:is_nil(<<>>)),
     ?_assert(etbx:is_nil(undefined)),
     ?_assert(etbx:is_nil()),
     ?_assert(etbx:is_nil(<<"">>)),
     ?_assertNot(etbx:is_nil(0)),
     ?_assertNot(etbx:is_nil([undefined])),
     ?_assertNot(etbx:is_nil([[]]))].

index_of_test_() ->
    [?_assertEqual(undefined, etbx:index_of(foo, [])),
     ?_assertEqual(0,         etbx:index_of(foo, [foo, bar])),
     ?_assertEqual(1,         etbx:index_of(foo, [bar, foo])),
     ?_assertEqual(1,         etbx:index_of(foo, [baz, foo, bar])),
     ?_assertEqual(2,         etbx:index_of(foo, [baz, bar, foo])),
     ?_assertEqual(undefined, etbx:index_of(foo, [baz, bar]))].

to_rec_test_() ->
    [?_assertEqual(#frob{foo="foo", bar="bar", baz="baz"}, 
                   etbx:to_rec(?RECSPEC(frob), [{baz, "baz"}, {foo, "foo"}])),
     ?_assertEqual(#frob{foo="foo", bar="bar", baz="baz"}, 
                   etbx:to_rec(?RECSPEC(frob), [{"baz", "baz"}, {<<"foo">>, "foo"}])),
     ?_assertEqual(#frob{},
                   etbx:to_rec(?RECSPEC(frob), [])),
     ?_assertEqual(#frob{},
                   etbx:to_rec(?RECSPEC(frob), [{bad, "bad"}]))].

contains_test_() ->
    [?_assert(etbx:contains(foo, [foo, bar, baz])),
     ?_assert(etbx:contains(foo, [foo])),
     ?_assert(etbx:contains(foo, [bar, foo, baz])),
     ?_assert(etbx:contains(foo, [bar, baz, foo])),
     ?_assertNot(etbx:contains(foo, [])),
     ?_assertNot(etbx:contains(foo, [bar, baz])),
     ?_assert(etbx:contains(foo, [{foo, "foo"}, {bar, "bar"}])),
     ?_assert(etbx:contains(foo, [{foo, "foo"}])),
     ?_assert(etbx:contains(foo, [{bar, "bar"}, {foo, "foo"}, {baz, "baz"}])),
     ?_assert(etbx:contains(foo, [{bar, "bar"}, {baz, "baz"}, {foo, "foo"}])),
     ?_assertNot(etbx:contains(foo, [{}])),
     ?_assertNot(etbx:contains(foo, [{bar, "bar"}, {baz, "baz"}]))].

update_test_() ->
    [?_assertEqual(etbx:update(foo, "foo", [{foo, ""}, {bar, "bar"}]),
                   [{foo, "foo"}, {bar, "bar"}]),
     ?_assertEqual(etbx:update(foo, "foo", []),
                   [{foo, "foo"}]),
     ?_assertEqual(etbx:update(foo, "foo", [{bar, "bar"}]),
                   [{foo, "foo"}, {bar, "bar"}]),
     ?_assertEqual(etbx:update(foo, "foo", {[{bar, "bar"}]}),
                   {[{foo, "foo"}, {bar, "bar"}]})].
     
to_list_test_() ->
    [?_assertEqual(etbx:to_list(<<"foo">>),       "foo"),
     ?_assertEqual(etbx:to_list({foo, bar, baz}), [foo, bar, baz]),
     ?_assertEqual(etbx:to_list(42),              "42"),
     ?_assertEqual(etbx:to_list("foo"),           "foo"),
     ?_assertEqual(etbx:to_list(sets:add_element(foo, sets:new())),
                  [foo]),
     ?_assertEqual(etbx:to_list(foo),             "foo")].

to_string_test_() ->
    [?_assertEqual(etbx:to_string(<<"foo">>), "foo"),
     ?_assertEqual(etbx:to_string(42),        "42"),
     ?_assertEqual(etbx:to_string(2.7183),    "2.71830000000000016058e+00"),
     ?_assertEqual(etbx:to_string("foo"),     "foo"),
     ?_assertEqual(etbx:to_string(foo),       "foo")].

to_binary_test_() ->
    [?_assertEqual(etbx:to_binary("foo"),     <<"foo">>),
     ?_assertEqual(etbx:to_binary(42),        <<42>>),
     ?_assertEqual(etbx:to_binary(foo),       <<"foo">>),
     ?_assertEqual(etbx:to_binary(<<"foo">>), <<"foo">>)].

to_atom_test_() ->
    [?_assertError(badarg, etbx:to_atom(42)),
     ?_assertError(badarg, etbx:to_atom(2.7183)),
     ?_assertError(badarg, etbx:to_atom("nofoo")),
     ?_assertError(badarg, etbx:to_atom(<<"tidakfoo">>)),
     ?_assertEqual(etbx:to_atom(foo),                  foo),
     ?_assertEqual(etbx:to_atom("hasfoo",     unsafe), hasfoo),
     ?_assertEqual(etbx:to_atom(<<"adafoo">>, unsafe), adafoo),
     ?_assertEqual(etbx:to_atom(24,           unsafe), '24'),
     ?_assertEqual(etbx:to_atom(1.618,        unsafe),
                   '1.61800000000000010481e+00')].

index_of_any_test_() ->
    [?_assertEqual(undefined, etbx:index_of_any([foo], [])),
     ?_assertEqual(0,         etbx:index_of_any([man, foo], [foo, bar])),
     ?_assertEqual(1,         etbx:index_of_any([foo, baz], [bar, foo])),
     ?_assertEqual(2,         etbx:index_of_any([bar, foo], [baz, foo, bar])),
     ?_assertEqual(2,         etbx:index_of_any([foo], [baz, bar, foo])),
     ?_assertEqual(undefined, etbx:index_of_any([foo], [baz, bar]))].

merge_test_() ->
    [?_assertEqual([],               etbx:merge([])),
     ?_assertEqual([{b,2}, {a,1}],   etbx:merge([[{a,1}, {b,2}], []])),
     ?_assertEqual([{b,2}, {a,1}],   etbx:merge([[{a,1}], [{b,2}]])),
     ?_assertEqual([{b,0}, {a,1}],   etbx:merge([[{a,1}, {b,2}], [{b,0}]])),
     ?_assertEqual({[{b,0}, {a,1}]}, etbx:merge([{[{a,1}, {b,2}]}, 
                                                 {[{b,0}]}])),
     ?_assertEqual({[{b,0}, {a,1}]}, etbx:merge([{[{a,1}, {b,2}]}, 
                                                 [{b,0}]]))].

get_value_test_() ->
    [?_assertEqual(foo, etbx:get_value(bar, #{bar => foo})),
     ?_assertEqual(foo, etbx:get_value(bar, [{bar, foo}])),
     ?_assertEqual(baz, etbx:get_value(foo, #{bar => foo}, baz))].

select_test_() ->
    [?_assertEqual(#{foo => 1, bar => 2}, 
                   etbx:select(#{ foo => 1, bar => 2, baz => 3},
                               [foo, bar])),
     ?_assertEqual(#{},
                   etbx:select(#{ foo => 1, bar => 2, baz => 3}, [])),
     ?_assertEqual(#{},
                   etbx:select(#{ foo => 1, bar => 2, baz => 3}, [moo, choo])),
     ?_assertEqual([{bar, 2}, {foo, 1}], 
                   etbx:select([{foo, 1}, {bar, 2}, {baz, 3}], 
                               [foo, bar])),
     ?_assertEqual([],
                   etbx:select([{foo, 1}, {bar, 2}, {baz, 3}],
                               [moo, choo]))].

remap_test_() ->
    [?_assertEqual([{foo, 1}, {bar, [{baz, 2}]}],
                   etbx:remap(fun(X) -> X + 1 end, 
                              [{foo, 0}, {bar, [{baz, 1}]}])),
     ?_assertEqual([],
                   etbx:remap(fun(X) -> X end, [])),
     ?_assertEqual([{foo, 1}, {bar, 2}],
                   etbx:remap(fun(X) -> X + 1 end,
                              [{foo, 0}, {bar, 1}]))].

expand_test_() ->
    [?_assertEqual([{a, 
                     [{2, 1}, 1, 2],
                     {[{b, 1}, {c, 2}]}}],
                   etbx:expand([{foo, 1}, {bar, 2}, {baz, foo}],
                               [{a, 
                                 [{bar, foo}, foo, bar],
                                 {[{b, baz}, {c, bar}]}}])),
     ?_assertException(throw, {too_many_expansions, _},
                       etbx:expand([{foo, [{bar, 2}]}, 
                                    {bar, {[{foo, 1}]}}],
                                   foo))].

split_test_() ->
    [?_assertEqual({[], [a, b, c]}, etbx:split(0, [a, b, c])),
     ?_assertEqual({[], []},        etbx:split(3, [])),
     ?_assertEqual({[a, b, c], []}, etbx:split(4, [a, b, c])),
     ?_assertEqual({[a, b], [c]},   etbx:split(2, [a, b, c]))].

partition_test_() ->
    [?_assertEqual([], etbx:partition(3, [])),
     ?_assertEqual([], etbx:partition(0, [a, b, c])),
     ?_assertEqual([[a, b], [c, d]], etbx:partition(2, [a, b, c, d])),
     ?_assertEqual([[a, b, c], [d]], etbx:partition(3, [a, b, c, d])),
     ?_assertEqual([[a, b, c, d]],   etbx:partition(4, [a, b, c, d]))].

pad_test_() ->
    [?_assertEqual([foo, bar, baz], etbx:pad(3, [foo, bar], baz)),
     ?_assertEqual([foo, bar, baz], etbx:pad(3, [foo, bar, baz], cho))].

seq_test_() ->
    [?_assertEqual([1, 2, 3, 4], etbx:take(4, [1, 2, 3, 4, 5])),
     ?_assertEqual([1, 2, 3],    etbx:take(4, [1, 2, 3])),
     ?_assertEqual([1, 2, 3, 4], 
                   etbx:take(4, etbx:seq(fun(Last) ->
                                                 V = Last + 1,
                                                 {V, V}
                                         end, 0))),
     ?_assertEqual([0, 1, 2, 3], etbx:take(4, etbx:range())),
     ?_assertEqual([1, 2, 3],    etbx:take(4, etbx:range(1, 4))),
     ?_assertEqual([2,5,8],      etbx:take(4, etbx:range(2, 10, 3))),
     ?_assertEqual([1,4,7,10],   etbx:doall(etbx:range(1, 12, 3))),
     ?_assertEqual([1, 2, 3, 4], etbx:doall(etbx:range(1,5)))].

