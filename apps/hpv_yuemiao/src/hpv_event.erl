%%%-------------------------------------------------------------------
%%% @author WeiMengHuan
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 11月 2021 11:30
%%%-------------------------------------------------------------------
-module(hpv_event).
%%%=======================STATEMENT====================
-description("hpv_event").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([send_log/1, do_send_log/4]).
%%%=======================INCLUDE======================

%%%=======================RECORD=======================

%%%=======================DEFINE=======================

%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Description: 
%% Inputs:
%% Returns: 
%% -----------------------------------------------------------------
do_send_log(_A, _Src, _Event, Args)->
	 vaccineHPV_push:send_log(Args).

send_log(Content)->
	wx_event_server:throw_event("hpv_yuemiao", send_log, Content).
	
%==========================DEFINE=======================