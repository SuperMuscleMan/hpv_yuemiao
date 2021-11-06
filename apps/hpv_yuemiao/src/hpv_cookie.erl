-module(hpv_cookie).
%%%=======================STATEMENT====================
-description("hpv_cookie").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([get_tk/0, set_tk/1, get_cookie/0, set_cookie/1]).
%%%=======================INCLUDE======================

%%%=======================RECORD=======================

%%%=======================DEFINE=======================

%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Func: 
%% Description: 
%% Returns: 
%% -----------------------------------------------------------------
set_cookie(Cookie)->
	wx_cfg:set(?MODULE, cookie,Cookie).
get_cookie()->
	wx_cfg:get(?MODULE, cookie).

set_tk(Tk)->
	wx_cfg:set(?MODULE, tk, Tk).
get_tk()->
	wx_cfg:get(?MODULE, tk).
%==========================DEFINE=======================