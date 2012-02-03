% Use: erlc hello.erl && erl -pa ./ebin -s hello run -s init stop -noshell

-module(hello).
-export([run/0]).

run() ->

    crypto:start(),
    application:start(emysql),

    emysql:add_pool(hello_pool, 1,
        "hello_username", "hello_password", "localhost", 3306,
        "hello_database", latin1),

    emysql:execute(hello_pool, <<"DELETE FROM investors where username = 'slepher'">>, []),

    emysql:transaction(
      hello_pool,
      fun(Connection) ->
              emysql_conn:execute(Connection, <<"INSERT INTO investors set username = 'slepher'">>, []),
              emysql:abort(just_abort)
      end),

    Result = emysql:execute(hello_pool, <<"SELECT id from investors where username = 'slepher'">>),
    {result_packet, _, _, [],<<>>} = Result,
    Result2 = 
        emysql:transaction(
          hello_pool,
          fun(Connection) ->
                  emysql_conn:execute(Connection, <<"INSERT INTO investors set username = 'slepher'">>, []),
                  emysql_conn:execute(Connection, <<"SELECT LAST_INSERT_ID()">>, [])
          end),
    {atomic, {result_packet, _, _, [[Val]],<<>>}} = Result2,
    io:format("~p~n", [Val]).
