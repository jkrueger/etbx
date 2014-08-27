%% @author Erick Gonzalez <erick@codemonkeylabs.de>
%% @doc The ETBX library is a set of Erlang ([http://www.erlang.org]) functions to perform common tasks that are a recurrent theme during development of Erlang applications.
%% The ETBX Serialized DB module offers a simple serialized database where the
%% file format can be user specified. No it is not supposed to 
%% be infinitely scalable, no it is not supposed to offer atomic transactions
%% and no it won't help with your incontinency problems either. It is just a
%% way to keep some database data on a file. This is handy for example for 
%% configuration files that content a list of entries, etc.

-module(etbx_sdb).
-vsn("1.0.0").
-export([erase/2, erase/1]).
-export([init/3]).
-export([lookup/2]).
-export([store/3]).
-record(db_obj, {type_marker = etbx_sdb::atom(),
                 dictionary::orddict:orddict(),
                 deserialize_fn::fun(),
                 serialize_fn::fun(),
                 filename::string()}).

%% @private
deserialize_db(_, Dict, <<>>) ->
    Dict;
deserialize_db(DeserializeFn, Dict, Data) ->
    case DeserializeFn(Data) of
        {ok, Key, Value, Remains} ->
            NewDict = orddict:store(Key, Value, Dict),
            deserialize_db(DeserializeFn, NewDict, Remains);
        _ ->
            Dict
    end.
    
%% @private
serialize_db(SerializeFn, Filename, Dict) when is_list(Filename) ->
    Data = serialize_db(SerializeFn, <<>>, orddict:to_list(Dict)),
    file:write_file(Filename, Data);
serialize_db(_, Data, []) ->
    Data;
serialize_db(SerializeFn, Data, [{K,V} | T]) ->
    NewData = SerializeFn(K, V),
    serialize_db(SerializeFn, <<Data/binary, NewData/binary>>, T).

%% @doc Initializes a DB object, reading its initial state from storage
init(DeserializeFn, SerializeFn, Filename) ->
    Data = case file:read_file(Filename) of
               {ok, Bytes} -> Bytes;
               _           -> <<>>
           end,
    Dict = deserialize_db(DeserializeFn, orddict:new(), Data),
    #db_obj{dictionary     = Dict,
            deserialize_fn = DeserializeFn, 
            serialize_fn   = SerializeFn,
            filename       = Filename}.

lookup(Key, DB) ->
    orddict:find(Key, DB#db_obj.dictionary).

store(Key, Value, DB) ->
    Filename = DB#db_obj.filename,
    NewDict  = orddict:store(Key, Value, DB#db_obj.dictionary),
    SerializeFn  = DB#db_obj.serialize_fn,
    case lookup(Key, DB) of
        {ok, _} ->
            serialize_db(SerializeFn, Filename, NewDict);
        error   ->
            Data = SerializeFn(Key, Value),
            file:write_file(Filename, Data, [append])
    end,
    DB#db_obj{dictionary=NewDict}.

erase(Key, DB) ->
    NewDict     = orddict:erase(Key, DB#db_obj.dictionary),
    SerializeFn = DB#db_obj.serialize_fn,
    Filename    = DB#db_obj.filename,
    serialize_db(SerializeFn, Filename, NewDict),
    DB#db_obj{dictionary=NewDict}.
erase(DB) ->
    NewDict=orddict:new(),
    SerializeFn = DB#db_obj.serialize_fn,
    Filename    = DB#db_obj.filename,
    serialize_db(SerializeFn, Filename, NewDict),
    DB#db_obj{dictionary=NewDict}.
