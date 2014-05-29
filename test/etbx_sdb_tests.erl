-module(etbx_sdb_tests).
-compile(export_all).
-include("etbx.hrl").
-include_lib("eunit/include/eunit.hrl").

serialize_fn(K, V) ->
    KB = etbx:to_binary(K),
    VB = etbx:to_binary(V),
    <<KB/binary, $:, VB/binary, $\n>>.

deserialize_fn(Data) ->
    case Data of 
        <<>> -> no_data;
        B when is_binary(B) ->
            {Pos, _} = binary:match(B, <<$\n>>),
            <<H:Pos/binary, _, Remains/binary>> = B,
            [K, V]  = binary:split(<<H/binary>>, <<$:>>),
            {ok, K, V, Remains};
        _ ->
            error
    end.

has_bar(DB) ->
    [?_assertEqual({ok, <<"bar">>}, etbx_sdb:lookup(<<"foo">>, DB))].

has_qux(DB) ->
    [?_assertEqual({ok, <<"qux">>}, etbx_sdb:lookup(<<"baz">>, DB))].

init_sdb() ->
    etbx_sdb:init(fun deserialize_fn/1,
                  fun serialize_fn/2,
                  "test.sdb").
    
sdb_test_1() ->
    {setup,
     fun() ->
             file:delete("test.sdb"),
             DB = init_sdb(),
             etbx_sdb:store(<<"foo">>, <<"bar">>, DB)
     end,
     fun has_bar/1}.


sdb_test_2() ->
    {setup, fun init_sdb/0, fun has_bar/1}.

sdb_test_3() ->
    {setup, fun init_sdb/0, 
     fun(DB) ->
             [?_assertEqual(error, etbx_sdb:lookup(<<"baz">>, DB))]
     end}.

sdb_test_4() ->
    {setup,
     fun() ->
             DB = init_sdb(),
             etbx_sdb:store(<<"baz">>, <<"qux">>, DB)
     end,
     fun has_qux/1}.

sdb_test_() ->
    {inorder,
     [{generator, fun sdb_test_1/0},
      {generator, fun sdb_test_2/0},
      {generator, fun sdb_test_3/0},
      {generator, fun sdb_test_4/0}]}.
