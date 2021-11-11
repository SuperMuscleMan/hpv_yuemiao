%%%-------------------------------------------------------------------
%%% @author WeiMengHuan
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 11月 2021 20:54
%%%-------------------------------------------------------------------
-module(vaccineHPV).
%%%=======================STATEMENT====================
-description("vaccineHPV").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([get_departments/0, get_not_read_notice/2, check/0, get_find_by_user_id/2, get_now/2, get_total/0]).
%%%=======================INCLUDE======================
-include("vaccineHPV.hrl").

-include_lib("wx_log_library/include/wx_log.hrl").
%%%=======================RECORD=======================

%%%=======================DEFINE=======================
%%-define(LINKMANID, <<"7197561">>).
-define(LINKMANID, hpv_cache:get_linkmanid()).
-define(COOKIE, hpv_cache:get_cookie()).
-define(TK, hpv_cache:get_tk()).
-define(CARDNO, hpv_cache:get_card_no()).
-define(CURDATELIST, hpv_cache:get_next_few_months()).
-define(REQUEST_TIMEOUT, 10000). %% 请求超时10s
-define(HTTPOPTIONS,
	[
		{timeout, ?REQUEST_TIMEOUT}%% 请求超时3s
	]).
-define(OPTIONS,
	[
		{sync, true},
		{full_result, false},
		{body_format, binary}
	]).
%%%=================EXPORTED FUNCTIONS=================
%% -----------------------------------------------------------------
%% Description:定时检测
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
check() ->
	check(hpv_cache:get_departments()).
check(Rows) ->
	?LOG(["Start detection."]),
	{FrontList, BackList, BackEntityR} = loop_check_is_can(Rows, [], [], []),
	LinkManId = ?LINKMANID,
	Cookie = ?COOKIE,
	Tk = ?TK,
	CardNo = ?CARDNO,%% 身份证ID用于判断年龄
	%% 订阅
	subscribe(FrontList, LinkManId, Cookie, Tk),
	?LOG(["Detection information.", {"Subscribable quantity:", length(FrontList)},
		{"Reserved quantity:", length(BackList)}]),
	%% 预约
	case BackEntityR of
		[] ->
			ok;
		_ ->
			?LOG(["Start making an appointment!!!"]),
			Now = get_now(Cookie, Tk),
			CurDateList = ?CURDATELIST,
			add(BackEntityR, LinkManId, Cookie, Tk, CardNo, Now, CurDateList),
			vaccineHPV_push:send(BackList),
			?LOG(["The appointment is over!!!"])
	end.

%% -----------------------------------------------------------------
%% Description: 1、获取信息列表
%% Inputs:
%% Returns: 
%% -----------------------------------------------------------------
get_departments() ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT
		],
	ContentType = ?HEAD_CONTENT_TYPE_URLENCODED,
	Total = hpv_cache:get_total(),
	Body = lists:flatten(["offset=0&limit=",integer_to_list(Total),"&regionCode=5101&isOpen=1&sortType=1&customId=3"]),
	Request = {?URL_GET_DEPARTMENTS, Header, ContentType, Body},
	{ok, Response} = httpc:request(post, Request, ?HTTPOPTIONS, ?OPTIONS),
	case parse_body(Response) of
		{ok, Data} ->
			Rows = maps:get(<<"rows">>, Data),
%%			Total = maps:get(<<"total">>, Data),
			hpv_cache:set_departments(Rows),
			case ets:info(departments) of
				undefined  ->
					hpv_cache:set_departments2(Rows, []);
				_->
					NewRows = hpv_cache:set_departments2(Rows, []),
					check(NewRows)
end,
			?LOG("update departments information list successfully.");
		Err ->
			?LOG(["update departments information list failed.", {err, Err}])
	end.

%% -----------------------------------------------------------------
%% Description:定时获取社区总数
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
get_total()->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT
		],
	ContentType = ?HEAD_CONTENT_TYPE_URLENCODED,
	Body = lists:flatten(["offset=0&limit=","1","&regionCode=5101&isOpen=1&sortType=1&customId=3"]),
	Request = {?URL_GET_DEPARTMENTS, Header, ContentType, Body},
	{ok, Response} = httpc:request(post, Request, ?HTTPOPTIONS, ?OPTIONS),
	case parse_body(Response) of
		{ok, Data} ->
			Total = maps:get(<<"total">>, Data),
			case hpv_cache:get_total() of
				Total ->
					ok;
				OldTotal->
					Diff = Total - OldTotal,
					?LOG(["There are new.", {diff, Diff}]),
					hpv_event:send_log(unicode:characters_to_binary(
						lists:concat(["有新增网点:", Diff]))),
					hpv_cache:set_total(Total),
					get_departments()
			end;
		Err ->
			?LOG(["get total failed", {err, Err}])
	end.
	

%% -----------------------------------------------------------------
%% Description: 2、判断是否可预约
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
is_can_subscribe(Id, DepaCode, VaccineCode, LinkManId, Cookie, Tk) ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Request = {[?URL_IS_CAN_SUBSCRIBE,
		"?id=", Id, "&depaCode=", DepaCode, "&vaccineCode=", VaccineCode, "&linkmanId=", LinkManId], Header},
	
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	case parse_body(Response) of
		{ok, Data} ->
			{maps:get(<<"typeCode">>, Data), maps:get(<<"ticket">>, Data)};
		Err ->
			Err
	end.

%% -----------------------------------------------------------------
%% Description:3、订阅
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
subscribe([DepartmentInfo | T], LinkManId, Cookie, Tk) ->
	subscribe_(DepartmentInfo, LinkManId, Cookie, Tk),
	subscribe(T, LinkManId, Cookie, Tk);
subscribe([], _LinkManId, _Cookie, _Tk) ->
	ok.
subscribe_({DepaId, DepaName}, LinkManId, Cookie, Tk) ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Request = {[?URL_DELAYSUBSCRIBE,
		"?linkmanId=", LinkManId, "&depaVaccId=", DepaId], Header},
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	hpv_event:send_log(unicode:characters_to_binary(["【新增社区网点】", DepaName, $\r,$\n, "地址：", [?URL_DELAYSUBSCRIBE,
		"?linkmanId=", LinkManId, "&depaVaccId=", DepaId]])),
	case parse_body(Response) of
		{ok, _} ->
			?LOG(["subscritbe Success!", {linkManId, LinkManId}, {departmentId, DepaId}]);
		Err ->
			?LOG(["subscritbe Failed!", {linkManId, LinkManId}, {departmentId, DepaId},
				{err, Err}])
	end.
%% -----------------------------------------------------------------
%% Description:4、订阅
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
add([H | T], LinkManId, Cookie, Tk, CardNo, Now, CurDateList) ->
	case add_(CurDateList, H, LinkManId, Cookie, Tk, CardNo, Now) of
		{ok, _} ->
			hpv_cache:set_is_continue(),
			vaccineHPV_push:send_success(H),
			?LOG("Give you joy!!! The appointment was successful!!!");
		_ ->
			add(T, LinkManId, Cookie, Tk, CardNo, Now, CurDateList)
	end;
add([], _, _, _, _, _, _) ->
	ok.
add_([CurDate | NextDateList], Item, LinkManId, Cookie, Tk, CardNo, Now) ->
	#{<<"code">> := DepartCode, <<"vaccineCode">> := VaccineCode, <<"depaVaccId">> := DepartmentVaccineId0,
		<<"ticket">> := Ticket} = Item,
	DepartmentVaccineId = integer_to_binary(DepartmentVaccineId0),
%%	获取日期[<<"2021-11-15">>,<<"2021-11-16">>,<<"2021-11-13">>,<<"2021-11-11">>,<<"2021-11-17">>]
	{ok, DateList} = add_get_date_list(DepartCode, VaccineCode, DepartmentVaccineId, CurDate, LinkManId, Cookie, Tk),
%%	获取具体时间
	case DateList of
		[] ->
			add_(NextDateList, Item, LinkManId, Cookie, Tk, CardNo, Now);
		_ ->
			?LOG(["List of selectable dates.", {curDate, CurDate}, {selectable, DateList}]),
			%%获取指定日期是否可预约 [{\"maxSub\":1,\"day\":\"20211115\"},{\"maxSub\":0,\"day\":\"20211112\"},{\"maxSub\":1,\"day\":\"20211110\"},{\"maxSub\":1,\"day\":\"20211108\"}]
			{ok, TimeList} = add_get_time_list(DepartCode, VaccineCode, DepartmentVaccineId, DateList, Cookie, Tk),
			case TimeList of
				[] ->
					?LOG(["The reservation number is gone!", {item, Item}, {dateList, DateList}]);
				_ ->
					?LOG(["List of selectable times.", {timeList, TimeList}]),
					DetailList = add_get_detail(TimeList, DepartCode, VaccineCode, DepartmentVaccineId, LinkManId, Cookie, Tk, CardNo, []),
					case DetailList of
						[] ->
							?LOG(["No reservation number is used for each time period!", {item, Item}, {timeList, TimeList}]);
						_ ->
							?LOG(["selectable time period.", {period, DetailList}]),
							{TimeId, _, TimeDate_} = lists:last(lists:keysort(2, DetailList)),
							%%	发送add接口
							add_add(DepartCode, VaccineCode, LinkManId, TimeDate_, TimeId, DepartmentVaccineId, Now, Ticket, Cookie, Tk)
					end
			end
	end;
add_([], Item, _LinkManId, _Cookie, _Tk, _CardNo, _Now) ->
	?LOG(["Date list is empty.", {item, Item}]).

%% 获取日期列表
add_get_date_list(DepartCode, VaccineCode, DepartmentVaccineId, Date, LinkManId, Cookie, Tk) ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Request = {[?URL_WORKDAYSBYMONTH,
		"?depaCode=", DepartCode, "&linkmanId=", LinkManId, "&vaccCode=", VaccineCode, "&vaccIndex=1",
		"&departmentVaccineId=", DepartmentVaccineId, "&month=", Date], Header},
	
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	case parse_body(Response) of
		{ok, Data} ->
			{ok, maps:get(<<"dateList">>, Data)};
		Err ->
			?ERR(["Faild to get date list.", {err, Err}]),
			{ok, []}
	end.
%% 获取时间列表
add_get_time_list(DepartCode, VaccineCode, DepartmentVaccineId, DateList0, Cookie, Tk) ->
	DateList = hpv_lib:parse_date_remove(DateList0),
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Request = {[?URL_FINDSUBSCRIBEAMOUNTBYDAYS,
		"?depaCode=", DepartCode, "&vaccCode=", VaccineCode, "&vaccIndex=1",
		"&days=", DateList, "&departmentVaccineId=", DepartmentVaccineId], Header},
	
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	case parse_body(Response) of
		{ok, Data} ->
			{ok, Data};
		Err ->
			?ERR(["Faild to get time list.", {err, Err}]),
			{ok, []}
	end.
%% 获取指定时间详情
add_get_detail([#{<<"maxSub">> := MaxSub, <<"day">> := Date} | T], DepartCode, VaccineCode, DepartmentVaccineId,
		LinkManId, Cookie, Tk, CardNo, R) when MaxSub =/= 0 ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	{ok, Date_} = hpv_lib:parse_date_add(Date),
	Request = {[?URL_DEPARTMENTWORKTIMES2,
		"?depaCode=", DepartCode, "&vaccCode=", VaccineCode, "&vaccIndex=1",
		"&subsribeDate=", Date_, "&departmentVaccineId=", DepartmentVaccineId, "&linkmanId=", LinkManId,
		"&idCardNo=", CardNo], Header},
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	{ok, #{<<"times">> := InfoList}} = parse_body(Response),
	TimeInfoList = maps:get(<<"data">>, InfoList),
	{TimeId, TimeMaxSub} = hpv_lib:times(TimeInfoList),
	add_get_detail(T, DepartCode, VaccineCode, DepartmentVaccineId, LinkManId, Cookie, Tk, CardNo, [{TimeId, TimeMaxSub, Date_} | R]);
add_get_detail([_ | T], DepartCode, VaccineCode, DepartmentVaccineId, LinkManId, Cookie, Tk, CardNo, R) ->
	add_get_detail(T, DepartCode, VaccineCode, DepartmentVaccineId, LinkManId, Cookie, Tk, CardNo, R);
add_get_detail([], _DepartCode, _VaccineCode, _DepartmentVaccineId, _LinkManId, _Cookie, _Tk, _CardNo, R) ->
	R.

add_add(DepartmentCode, VaccineCode, LinkManId, SubscribeDate, SubscribeTime, DepartmentVaccineId, Now, Ticket, Cookie, Tk) ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Dcmd5 = hpv_lib:dcmd5(DepartmentCode, Now, SubscribeTime),
	Request = {[?URL_ADD,
		"?vaccineCode=", VaccineCode, "&vaccineIndex=1", "&linkmanId=", LinkManId,
		"&subscribeDate=", SubscribeDate, "&subscirbeTime=", SubscribeTime,
		"&departmentVaccineId=", DepartmentVaccineId, "&depaCode=", Dcmd5,
		"&serviceFee=0", "&ticket=", Ticket], Header},
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	{ok, _D} = parse_body(Response).

%% -----------------------------------------------------------------
%% Func:
%% Description:获取未读消息（用于判断cookie是否过期
%% Returns:
%% -----------------------------------------------------------------
get_not_read_notice(Cookie, Tk) ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Request = {?URL_GET_NOT_READ, Header},
	
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	case parse_body(Response) of
		{err_lose, _} ->
			err;
		_ ->
			ok
	end.

%% -----------------------------------------------------------------
%% Description:获取用户信息
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
get_find_by_user_id(Cookie, Tk) ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Request = {[?URL_FINDBYUSERID], Header},
	
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	{ok, List} = parse_body(Response),
	#{<<"idCardNo">> := CardNo, <<"id">> := LinkManId} = lists:last(List),
	{CardNo, integer_to_binary(LinkManId)}.
%% -----------------------------------------------------------------
%% Description:获取服务器时间
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
get_now(Cookie, Tk) ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Request = {[?URL_NOW], Header},
	
	{ok, Response} = httpc:request(get, Request, ?HTTPOPTIONS, ?OPTIONS),
	{ok, Data} = parse_body(Response),
	Data.


%==========================DEFINE=======================

parse_body({200, Bin}) ->
	Json = jsx:decode(Bin),
	case check_body_code(Json) of
		ok ->
			{ok, maps:get(<<"data">>, Json)};
		Err ->
			Err
	end;
parse_body(Data) ->
	{err_parse, Data}.
%% depaVaccId表示社区id；vaccineCode表示疫苗id
loop_check_is_can([#{<<"depaVaccId">> := DepaVaccId, <<"code">> := DepaCode, <<"vaccineCode">> := VaccineCode} = H | T],
		FrontR, BackR, BackEntityR) ->
	timer:sleep(hpv_cache:get_delay()),
	DepaVaccId1 = integer_to_list(DepaVaccId),
	case is_can_subscribe(DepaVaccId1, DepaCode, VaccineCode, ?LINKMANID, ?COOKIE, ?TK) of
		{?TYPECODE_CANSUBSCRIBE, Ticket} ->%% 可预约
			#{<<"imgUrl">> := ImgUrl, <<"name">> := Name, <<"vaccineName">> := Desc} = H,
			loop_check_is_can(T, FrontR, [{ImgUrl, Name, Desc} | BackR], [H#{<<"ticket">> => Ticket} | BackEntityR]);
		{?TYPECODE_DELAYSUBSCRIBE, _} ->%% 可订阅
			#{<<"name">> := Name} = H,
			loop_check_is_can(T, [{DepaVaccId1, Name} | FrontR], BackR, BackEntityR);
		_ ->
			loop_check_is_can(T, FrontR, BackR, BackEntityR)
	end;
loop_check_is_can([], FrontR, BackR, BackEntityR) ->
	{FrontR, BackR, BackEntityR}.

check_body_code(#{<<"code">> := <<"0000">>}) ->
	ok;
check_body_code(#{<<"code">> := <<"1001">>}) ->
	{err_lose, <<"cookie lose efficacy">>};
check_body_code(Data) ->
	{err_code, Data}.

