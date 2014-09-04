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
                  Property = extract_property(PH, Capture),
                  PropertyPart = #est_part{type = property, data = Property},
                  NewParts = 
                      if Prelude == <<>> ->
                              [PropertyPart | Acc ];
                         true ->
                              [PropertyPart |
                               [#est_part{type = chunk, data = Prelude} | Acc]]
                      end,
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
extract_property(Placeholder, [{Start, _Length}, {SubStart, SubLength}]) ->
    RStart = SubStart - Start,
    <<_:RStart/binary, Field:SubLength/binary, _/binary>> = Placeholder,
    case etbx:eval(Field) of
        {ok, Value, _} ->
            Value;
        E ->
            {error, Placeholder, E}
    end.

%% @doc
%% renders a precompiled template into an iolist using the model provided
-spec(render(est_rec(), [proplists:property()]) -> iolist()).
render(Part, Model) when is_record(Part, est_part) ->
    case Part#est_part.type of
        chunk ->
            Part#est_part.data;
        property ->
            proplists:get_value(Part#est_part.data, Model)
    end;
render(Template, Model) ->
    lists:foldl(
      fun(Part, A) ->
              [ render(Part, Model) | A ]
      end,
      [],
      Template#est_rec.parts).
