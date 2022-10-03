-module(btcMiner).
-import(string,[concat/2,slice/3]).
-export([minebtc/1,generateMatch/2,start/0]).



generateRandomString(Length)->
    get_random_string(Length,"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").

get_random_string(Length, AllowedChars) ->
    lists:foldl(fun(_, Acc) ->
                        [lists:nth(rand:uniform(length(AllowedChars)),
                                   AllowedChars)]
                            ++ Acc
                end, [], lists:seq(1, Length)).


generateBaseInputString()->
    Ufid="rshukla;",
    RandomString=generateRandomString(8),
    BaseInputString=concat(Ufid,RandomString),
    BaseInputString.
    
generateMatch(0,Match)->
    Match;
generateMatch(N,Match)->
    generateMatch(N-1,concat(Match,"0")).
    

checkNumberOfZeroes(Num,InputString)->
    LeadingZeroes=string:slice(InputString,0,Num),
    StringToMatch=generateMatch(Num,""),
    string:equal(LeadingZeroes,StringToMatch).



minebtc(NumZeros)->
    BaseInputString=generateBaseInputString(),
    mine(NumZeros,0,10000,BaseInputString).

mine(NumZeros,NonceStart,NonceStop,BaseInputString)->
    if
        NonceStart/=NonceStop->
            InputString=BaseInputString,
            %io:fwrite("~p\n",[InputString]),            
            GeneratedHash=io_lib:format("~64.16.0b", [binary:decode_unsigned(crypto:hash(sha256,InputString))]),
            Found=checkNumberOfZeroes(NumZeros,GeneratedHash),
            if 
                Found==true->
                    io:fwrite("~p\n",[Found]),
                    io:fwrite("~p  ======  ~p~n",[InputString,GeneratedHash]),
                    mine(NumZeros,NonceStart+1,NonceStop,generateBaseInputString());
                Found==false->
                    mine(NumZeros,NonceStart+1,NonceStop,generateBaseInputString())
            end;
        true->"Done"
    end.




start()->
    {ok, Difficulty} = io:fread("Enter the number of Required Leading Zeroes: ","~u"),
    minebtc(hd(Difficulty)).

