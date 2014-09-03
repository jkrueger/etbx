-module(etbx_est_tests).
-compile(export_all).
-include_lib("eunit/include/eunit.hrl").

est_test_() ->
    [?_assertEqual({est_rec,[{est_part, chunk, <<"!">>},
                             {est_part, property, foo},
                             {est_part, chunk, <<"hi ">>}]},
                   etbx_est:compile(<<"hi {{foo}}!">>)),
     ?_assertEqual({est_rec,[{est_part, chunk, <<"!">>},
                             {est_part, property, foo},
                             {est_part, chunk, <<"hi ">>}]},
                   etbx_est:compile(<<"hi {{'foo'}}!">>)),
     ?_assertEqual({est_rec,[{est_part, chunk, <<"!">>},
                             {est_part, property, <<"foo">>},
                             {est_part, chunk, <<"hi ">>}]},
                   etbx_est:compile(<<"hi {{  <<\"foo\">> }}!">>)),
     ?_assertEqual({est_rec,[{est_part, chunk, <<"!">>},
                             {est_part, property, foo},
                             {est_part, chunk, <<"hi ">>}]},
                   etbx_est:compile(<<"hi {{foo}}!">>)),
     ?_assertEqual({est_rec,[{est_part, property, bar},
                             {est_part, property, foo}]},
                   etbx_est:compile(<<"%'foo'%%bar%">>, "%(.*)%")),
     ?_assertEqual({est_rec,[{est_part, chunk, <<"hi mom!">>}]},
                   etbx_est:compile(<<"hi mom!">>))].
