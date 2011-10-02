-module(antplus_websockets_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _StartArgs) ->
    Config = application:get_all_env(antplus_websockets),
    Port = proplists:get_value(port, Config, 8080),
    ListenAddr = proplists:get_value(listen, Config, "localhost"),
    Serial = proplists:get_value(serial, Config, "/dev/ttyUSB0"),

    LoopFun = fun(Req) ->
                      antplus_websockets_server:handle_http(Req, ListenAddr, Port)
              end,

    WSLoop = fun(Ws) ->
                     antplus_websockets_server:handle_websocket(Ws)
             end,

    antplus_websockets_sup:start_link([
                                        {serial, Serial},
                                        {port, Port},
                                        {loop, LoopFun},
                                        {ws_loop, WSLoop},
                                        {ws_autoexit, false}
                                       ]).
stop(_State) ->
    ok.
