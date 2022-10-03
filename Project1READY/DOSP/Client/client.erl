-module(client).
-export([send/2, start/2, connect_to_server/2, listen/2]).

% send(ServerPID, Num) -> 
%     ServerPID ! {self(), Num}.

connect_to_server(SerPid, ServerNode) ->
    net_kernel:start([client, shortnames]),
    erlang:set_cookie(node(), dosp),
    %redundant line to setup similar cookie across connected machines.
    net_kernel:connect_node(ServerNode),
    net_adm:ping(ServerNode), % if ping is success only then send. This was a Pong.
    %Start client make server to register this client start client side worker process for mining with half of the available schedulers/cores.
    {SerPid, ServerNode} ! {clientPid, node(), registerClient, erlang:system_info(schedulers_online)*2},
    listen(SerPid, ServerNode).

listen(SerPid, ServerNode) ->
%This recursive process records Worker and sever requests and responds while keeping listening process alive.
    receive
        %Mining with provided Random strings by server
        {workerParameters, Param} ->
            RandomStringsList = element(3, Param),
            Workers = [spawn(worker, mine, [element(1, Param), 0, 1000000, Str, clientPid]) || Str <- RandomStringsList],
            io:format("Client has spawned ~p workers.~n", [length(Workers)]);
        {workerParameter, Param} ->
            spawn(worker, mine, [element(1, Param), 0, 1000000, element(2, Param), clientPid]);
        %What to do if the client side worker finds BTC. Inform Server.
        {foundBTC, Hash} ->
            {SerPid, ServerNode} ! {foundBTC, Hash};
        %Request new load for the worker process with the WorkerPid from server.
        {WorkerPid, requestNewLoad} ->
            {SerPid, ServerNode} ! {clientPid, node(), requestNewLoad},
            exit(WorkerPid, kill)%Kill the process later.
    end,
    listen(SerPid, ServerNode).


start(SerPid, ServerNode) ->
    c:cd("../Worker"),
    c:c(worker),
    %worker compilation before connecting server to this client

    register(clientPid, spawn(client, connect_to_server, [SerPid, ServerNode])).