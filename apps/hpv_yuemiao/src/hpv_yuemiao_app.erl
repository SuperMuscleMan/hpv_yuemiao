%%%-------------------------------------------------------------------
%% @doc hpv_yuemiao public API
%% @end
%%%-------------------------------------------------------------------

-module(hpv_yuemiao_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    hpv_yuemiao_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
