-module(antplus_websockets_sup).
-behaviour(supervisor).

-export([start_link/1]).

-export([init/1]).

start_link(Options) ->
    supervisor:start_link(?MODULE, Options).

init(Options) ->
    MisultinSpec = {misultin,
                     {misultin, start_link, [Options]},
                     permanent, infinity, supervisor, [misultin]
                    },

    Serial = proplists:get_value(serial, Options, "/dev/ttyUSB0"),
    ServerSpec = {antplus_websockets_server,
                   {antplus_websockets_server, start_link, [Serial]},
                   permanent, 60000, worker, [antplus_websockets_server]
                  },

    Folsom = {folsom_webmachine,
              {folsom_webmachine_sup, start_link, []},
              transient, infinity, supervisor, [folsom_webmachine_sup]},

    {ok, {{one_for_all, 5, 30}, [MisultinSpec, ServerSpec, Folsom]}}.

