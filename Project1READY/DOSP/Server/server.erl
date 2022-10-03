-module(server).
-export([startIt/1, start/0, listen/1, genRandStr/2]).

listen(Zeroes) ->
%This recursive propcess keeps the server alive and listening to the requests from worker and client->worker.
    receive
        %Found
        {foundBTC, BaseString, Hash} ->
            {_, Time1} = statistics(runtime),
            {_, Time2} = statistics(wall_clock),
            U1 = Time1 / 1000,
            U2 = Time2 / 1000,
            % This captures the real and CPU time when BTC is found and compares with the last called runtime and wall_clock.
            io:format("For ~p Hash COde: ~p~n", [BaseString, Hash]),
            io:format("Code CPU time=~p seconds, Real Clock: (~p) seconds~n. Cores(CPU Time/Real Time): ~p~n",[U1,U2, U1/U2]);
            %This are the involved logical cores for mining.

        %Register a client along with a workload alloted Half of the available schedulers.
        {ClientPid, ClientNode, registerClient, WorkersCount} ->
            RandomStringsList = [ genRandStr(8, "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")|| _ <- lists:seq(1, WorkersCount)],
            {ClientPid, ClientNode} ! {workerParameters, {genRandStr(Zeroes, "0"), genRandStr(8, "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"), RandomStringsList}};
        %New workload on the connected/registered client.
        {ClientPid, ClientNode, requestNewLoad} ->
            {ClientPid, ClientNode} ! {workerParameter, {genRandStr(Zeroes, "0"), genRandStr(8, "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")}};
        %Register a client along with a workload
        {ClientPid, ClientNode, registerClient} ->
            {ClientPid, ClientNode} ! {workerParameter, {genRandStr(Zeroes, "0"), string:concat("rshukla:", genRandStr(8, "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"))}};
        %New workload for the registered Worker process
        {WorkerPid, requestNewLoad} ->
            WorkerPid ! {workerParameters, {genRandStr(Zeroes, "0"), genRandStr(8, "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")}}
        end,
    listen(Zeroes).


genRandStr(L, AllowedCharset) ->
%This function generates L Length random string from a set of Allowed characterset.
    lists:foldl(
        fun(_, Acc) ->  [lists:nth(rand:uniform(length(AllowedCharset)), AllowedCharset)] ++ Acc end, 
        [], 
        lists:seq(1, L)).



startIt(Zeroes) -> 
    statistics(runtime),
    statistics(wall_clock),
    %this initiates CPU runtime and real clock.

    net_kernel:start([server, shortnames]),
    erlang:set_cookie(node(), dosp),
    %This is a redundant line to ensure same cookie setup.

    register(serPid, spawn(server, listen, [Zeroes])),
    %Master Server process to listen and respond to messages.

    List = [spawn(worker, mine, [genRandStr(Zeroes, "0"), 0, 10000000, string:concat("rshukla;", genRandStr(8, "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")) , serPid]) || _ <- lists:seq(1, erlang:system_info(schedulers_online)*4)],
    io:format("Number of server side workers spawned are: ~p.~n", [length(List)]).
    %register a list of processes (64) for mining at server side.


start() ->
    
    c:cd("../Worker"),
    c:c(worker),%worker code compilation before starting then server.

    {ok, Dzeros} = io:fread("Enter the number of Required Leading Zeroes (Prefix 0 string length): ","~u"),
    startIt(hd(Dzeros)).% start server.