%%%-------------------------------------------------------------------
%%% @author WeiMengHuan
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 11月 2021 18:54
%%%-------------------------------------------------------------------
-module(hpv_lib).
%%%=======================STATEMENT====================
-description("hpv_lib").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([parse_date_remove/1, parse_date_add/1, times/1, dcmd5/3, get_next_few_months/1, get_cookie/0, check_work_time_period/0]).
%%%=======================INCLUDE======================

%%%=======================RECORD=======================

%%%=======================DEFINE=======================

%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Description:工作时间判断
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
check_work_time_period() ->
	SecondPass = second_pass_today(),
	{StartTime, EndTime} = wx_cfg:get(hpv, work_time_period),
	SecondPass > StartTime andalso SecondPass < EndTime.

second_pass_today() ->
	{_, {H, M, S}} = wx_time:second_to_local_datetime(wx_time:now_second()),
	H * 3600 + M * 60 + S.

%% -----------------------------------------------------------------
%% Description: [<<"2021-11-15">>,<<"2021-11-16">>,<<"2021-11-13">>,<<"2021-11-11">>,<<"2021-11-17">>] 转 
%% ["20211117",",","20211111",",","20211113",",","20211116",",","20211115"]
%% Inputs:
%% Returns: 
%% -----------------------------------------------------------------
parse_date_remove(DateList) ->
	parse_date_remove(DateList, []).
parse_date_remove([H | T], []) ->
	H1 = re:replace(H, "-", <<>>, [global, {return, list}]),
	parse_date_remove(T, [H1]);
parse_date_remove([H | T], R) ->
	H1 = re:replace(H, "-", <<>>, [global, {return, list}]),
	parse_date_remove(T, [H1, "," | R]);
parse_date_remove([], R) ->
	R.

%% -----------------------------------------------------------------
%% Description:“20211111” 转 2021-11-11
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------x
parse_date_add(Date) ->
	case re:run(Date, "(\\d{4})(\\d{2})(\\d{2})", [{capture, [1, 2, 3], list}]) of
		{match, [Y, M, D]} ->
			{ok, [Y, "-", M, "-", D]};
		Err ->
			{err, Err}
	end.

times(List) ->
	times_(List, []).
times_([#{<<"id">> := TimeId, <<"maxSub">> := MaxSub} | T], R) ->
	times_(T, [{integer_to_binary(TimeId), MaxSub} | R]);
times_([], R) ->
	lists:last(lists:keysort(2, R)).
 

get_next_few_months(Num) ->
	{{Y, M, _D}, _} = wx_time:second_to_local_datetime(wx_time:now_second()),
	[[integer_to_list(Y), "-", wx_lib:integer_to_list(M, 2), "-", "01"] |
		get_next_few_months_(Num - 1, Y, M)].
get_next_few_months_(0, _Y, _M) ->
	[];
get_next_few_months_(Num, Y, M) ->
	NextM = (M + 1),
	{Y1, M1, D1} =
		if
			NextM > 12 -> {Y + 1, 1, 1};
			true -> {Y, NextM, 1}
		end,
	[[integer_to_list(Y1), "-", wx_lib:integer_to_list(M1, 2), "-", wx_lib:integer_to_list(D1, 2)] |
		get_next_few_months_(Num - 1, Y1, M1)].

get_cookie() ->
	Now = wx_time:now_second(),
	case hpv_cache:get_cookie_geting() of
		Expire when is_integer(Expire), Expire > Now
			-> ok;
		_ ->
			hpv_cache:set_cookie_geting(Now + 120),
			erlang:spawn(fun() ->
				case os:cmd("get_cookie") of
					[] ->
						hpv_event:send_log(unicode:characters_to_binary("cookie获取成功，持续检测中..."));
					_ ->
						hpv_event:send_log(unicode:characters_to_binary("cookie获取失败，请检查获取程序..."))
				end
						 end)
	end.

%==========================DEFINE=======================