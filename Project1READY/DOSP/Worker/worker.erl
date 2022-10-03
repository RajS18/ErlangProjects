-module(worker).
-export([mine/5, listen/1]).

mine(Zstr, Start, End, BaseStr, To) ->
    if
        Start =< End ->
            HCode = io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,string:concat(BaseStr, integer_to_list(Start))))]),
            case string:equal(string:slice(HCode,0,string:length(Zstr)), Zstr) of
                true ->
                    To ! {foundBTC, BaseStr, HCode},
                    mine(Zstr, Start+1, End, BaseStr, To);
                false ->
                    mine(Zstr, Start+1, End, BaseStr,To)
            end;
        true ->
            To ! {self(), requestNewLoad},
            listen(To)
    end.

listen(Sender) ->
    receive
        {workerParameters, Param} ->
            mine(element(1, Param), 0, 1000000, string:concat("rshukla;",element(2, Param)), Sender)%process to mine->Logic.(Iterative.)
        end,
    listen(Sender).