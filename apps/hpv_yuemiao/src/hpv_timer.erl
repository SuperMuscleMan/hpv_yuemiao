-module(hpv_timer).
%%%=======================STATEMENT====================
-description("hpv_timer").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([check/2, get_departments/2, get_next_few_months/2, get_total/2]).
%%%=======================INCLUDE======================
-include_lib("wx_log_library/include/wx_log.hrl").
%%%=======================RECORD=======================

%%%=======================DEFINE=======================

%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Func: 
%% Description: 定时检测
%% Returns: 
%% -----------------------------------------------------------------
check(_TimerKey, _A) ->
	Cookie = hpv_cache:get_cookie(),
	Tk = hpv_cache:get_tk(),
	case hpv_lib:check_work_time_period() of
		true ->
			case is_list(Cookie) andalso is_list(Tk) of
				false ->
					hpv_lib:get_cookie();
				_ ->
					case hpv_cache:get_is_continue() of
						false ->
							ok;
						_ ->
							case vaccineHPV:get_not_read_notice(Cookie, Tk) of
								ok ->
									vaccineHPV:check();
								err ->
									?LOG("Cookie Expiration"),
									hpv_event:send_log(unicode:characters_to_binary(
										"cookie过期，正在自动获取中...")),
									hpv_lib:get_cookie()
							end
					end
			end;
		_ ->
			ok
	end.

%% -----------------------------------------------------------------
%% Description:获取社区列表
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
get_departments(_TimerKey, _A) ->
	vaccineHPV:get_departments().

%% -----------------------------------------------------------------
%% Description:获取最近几个月
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
get_next_few_months(_TimerKey, [Num]) ->
	List = hpv_lib:get_next_few_months(Num),
	hpv_cache:set_next_few_months(List).

%% -----------------------------------------------------------------
%% Description:获取总数
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
get_total(_TImeKey, _A)->
	vaccineHPV:get_total().

%==========================DEFINE=======================