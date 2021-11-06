-module(hpv_timer).
%%%=======================STATEMENT====================
-description("hpv_timer").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([check/2]).
%%%=======================INCLUDE======================

%%%=======================RECORD=======================

%%%=======================DEFINE=======================

%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Func: 
%% Description: 
%% Returns: 
%% -----------------------------------------------------------------
check(_TimerKey, _A) ->
	Cookie = hpv_cookie:get_cookie(),
	Tk = hpv_cookie:get_tk(),
	case vaccineHPV:get_not_read_notice(Cookie, Tk) of
		ok ->
			 io:format("MODULE:[~p]-LIINE:[~p] | valid:~p~n", [?MODULE, ?LINE, {valid}]),
			vaccineHPV:get_departments();
		err ->
			io:format("MODULE:[~p]-LIINE:[~p] | cookie_lost:~p~n", [?MODULE, ?LINE, {cookie_lost}])
	end.

%==========================DEFINE=======================