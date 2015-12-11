-module(etbx_est).
-export([compile/1, compile/2]).
-export([render/2]).
-record(est_part, { type::binary(), data::any() }).
-record(est_rec,  { parts::list(est_part) }).

-type est_rec()  :: est_rec.

%% @doc
%% same as compile(Template, <<"{{(.*)}}">>)
-spec(compile(string() | binary()) -> est_rec()).
compile(Template) ->
    compile(Template, <<"{{(.*)}}">>).

%% @doc
%% compiles a template with the given placeholder pattern
-spec(compile(string() | binary(), string() | binary()) -> est_rec()).
compile(Template0, PlaceholderPattern0) ->
    PlaceholderPattern = etbx:to_binary(PlaceholderPattern0),
    Template           = etbx:to_binary(Template0),

    Matches = case re:run(Template, PlaceholderPattern, [global, ungreedy]) of
                  {match, L} ->
                      L;
                  _ ->
                      []
              end,
    {RParts, _, Rest} = 
        lists:foldl(
          fun([{Start, PHL}, _] = Capture, {Acc, O, R}) ->
                  PreL = Start - O,
                  <<Prelude:PreL/binary, PH:PHL/binary, Epilogue/binary>> = R,
                  Part     = extract_part(PH, Capture),
                  NewParts = 
                      [Part |
                       if Prelude == <<>> ->
                               Acc;
                          true ->
                               [#est_part{type = chunk, data = Prelude} | Acc]
                       end],
                  {NewParts, Start + PHL, Epilogue}
          end,
          {[], 0, Template},
          Matches),
    if Rest == <<>> ->
            #est_rec{parts = RParts};
       true ->
            #est_rec{parts = [#est_part{type = chunk, data = Rest} | RParts]}
    end.

%% @private
extract_part(Placeholder, [{Start, _Length}, {SubStart, SubLength}]) ->
    RStart = SubStart - Start,
    <<_:RStart/binary, Field:SubLength/binary, _/binary>> = Placeholder,
    case re:run(Field, <<"\s*&(.*)&\s*">>) of
        {match, [{0, SubLength}, {EStart, ELen}]} ->
            <<_:EStart/binary, Expr:ELen/binary, _/binary>> = Field,
            #est_part{ type = expression, data = Expr };
        _ ->
            Property =
                case etbx:eval(Field) of
                    {ok, Value, _} ->
                        Value;
                    E ->
                        {error, Placeholder, E}
                end,
            #est_part{type = property, data = Property}
    end.

%% @doc
%% renders a precompiled template into an iolist using the model provided
-spec(render(est_rec(), [proplists:property()], any()) -> iolist()).
render(Part, Model, DefVal) when is_record(Part, est_part) ->
    case Part#est_part.type of
        chunk ->
            Part#est_part.data;
        expression ->
            Scope = [{'_@', fun etbx:get_value/2},
                     {'_@@', fun etbx:get_value/3},
                     {'__', Model}],
            case catch etbx:eval(Part#est_part.data, Scope) of
                {ok, Value, _} ->
                    case Value of
                        X when is_binary(X) -> X;
                        X when is_number(X) -> etbx:to_binary(X);
                        X when is_atom(X)   -> etbx:to_binary(X);
                        X                   -> io_lib:format("~w", [X])
                    end;
                {error, Error} ->
                    Error;
                {'EXIT', {Error, _}} ->
                    Error
            end;
        property ->
            case etbx:get_in(Part#est_part.data, Model, DefVal) of
                N when is_binary(N) ->
                    N;
                N when is_list(N) ->
                    N;
                N ->
                    etbx:to_string(N)
            end
    end;
render(Template, Model, DefVal) ->
    lists:foldl(
      fun(Part, A) ->
              [ render(Part, Model, DefVal) | A ]
      end,
      [],
      Template#est_rec.parts).

%% @doc
%% Same as render(Template, Model, <<"undefined">>)
-spec(render(est_rec(), [proplists:property()]) -> iolist()).
render(Template, Model) ->
    render(Template, Model, <<"undefined">>).
