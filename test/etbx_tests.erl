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
                   [{foo, "foo"}, {bar, "bar"}])].
     
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
    [?_assertEqual([],             etbx:merge([])),
     ?_assertEqual([{b,2}, {a,1}], etbx:merge([[{a,1}, {b,2}], []])),
     ?_assertEqual([{b,2}, {a,1}], etbx:merge([[{a,1}], [{b,2}]])),
     ?_assertEqual([{b,0}, {a,1}], etbx:merge([[{a,1}, {b,2}], [{b,0}]]))].

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
