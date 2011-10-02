-module(antplus_websockets_server).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([start_link/1, handle_http/3, handle_websocket/1]).

-record(state, {port}).

start_link(SerialDevice) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, SerialDevice, []).

init(SerialDevice) ->
    folsom_metrics:new_histogram(<<"hrm">>),
    process_flag(trap_exit,true),
    Bin = filename:join([filename:dirname(code:which(?MODULE)),"..", "priv", "hrm"]),
    Cmd = lists:flatten(io_lib:format("~s -g -t 5 -f ~s", [Bin, SerialDevice])),
    io:format("hrm command: ~p~n", [Cmd]),
    Port = open_port({spawn, Cmd}, []),
    {ok, #state{port = Port}}.

handle_call(get_data, _From, #state{port = Port} = State) ->
    receive
        {Port, {data, Data}} ->
            %io:format("data: ~p~n", [Data]),
            {Int, _} = string:to_integer(Data),
            JSON = jiffy:encode({[{data, {[{hrm, Int}]}}]}),
            folsom_metrics:notify({<<"hrm">>, Int}),
            {reply, JSON, State};
        Other ->
            io:format("got something unexpected: ~p~n", [Other])
    after 2000 ->
	{reply, jiffy:encode({[{data, {[{hrm, 0}]}}]}), State}
    end.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'EXIT', Port, Reason}, #state{port = Port} = State) ->
    {stop, {port_terminated, Reason}, State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate({port_terminated, _Reason}, _State) ->
    ok;
terminate(_Reason, #state{port = Port} = _State) ->
    port_close(Port).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

handle_http(Req, ListenAddr, Port) ->
    Req:ok([{"Content-Type", "text/html"}],

["<html>
		<head>
			<script type=\"text/javascript\">
				function addStatus(text){
				document.getElementById('status').innerHTML = document.getElementById('status').innerHTML + text + \"<br>\";
				}
				function ready(){
					if (\"WebSocket\" in window) {
						// browser supports websockets
						var ws = new WebSocket(\"ws://", ListenAddr, ":", erlang:integer_to_list(Port) ,"/service\");
						ws.onmessage = function (evt) {
							var receivedMsg = evt.data;
							addStatus(receivedMsg);
						};
					} else {
						// browser does not support websockets
						addStatus(\"sorry, your browser does not support websockets.\");
					}
				}
			</script>
		</head>
		<body onload=\"ready();\">
			<div id=\"status\"></div>
		</body>
	</html>"]).

handle_websocket(Ws) ->
    receive
	{browser, Data} ->
            Ws:send(["received '", Data, "'"]),
            handle_websocket(Ws);
        closed ->
            io:format("The WebSocket was CLOSED!~n");
        _Ignore ->
            handle_websocket(Ws)
    after 500 ->
            Ws:send(gen_server:call(?MODULE, get_data)),
            handle_websocket(Ws)
    end.

