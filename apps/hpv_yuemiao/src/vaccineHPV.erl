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
-export([get_departments/0, get_not_read_notice/2]).
%%%=======================INCLUDE======================
-include("vaccineHPV.hrl").
%%%=======================RECORD=======================

%%%=======================DEFINE=======================
-define(LINKMANID, <<"7197561">>).
-define(COOKIE, hpv_cookie:get_cookie()).
-define(TK, hpv_cookie:get_tk()).
-define(BODY_GET_DEPARTMENTS, <<"offset=0&limit=45&regionCode=5101&isOpen=1&sortType=1&customId=3">>).
%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Description: 获取信息列表
%% Inputs:
%% Returns: 
%% -----------------------------------------------------------------
get_departments() ->
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", ?COOKIE},
			{"tk", ?TK}
		],
	ContentType = ?HEAD_CONTENT_TYPE_URLENCODED,
	HttpOptions =
		[
			{timeout, timer:seconds(3)}%% 请求超时3s
		],
	Options =
		[
			{sync, true},
			{full_result, false},
			{body_format, binary}
		],
	Body = ?BODY_GET_DEPARTMENTS,
	Request = {?URL_GET_DEPARTMENTS, Header, ContentType, Body},
	{ok, Response} = httpc:request(post, Request, HttpOptions, Options),
	case parse_body(Response) of
		{ok, Data} ->
			Rows = maps:get(<<"rows">>, Data),
			InfoList = loop_check_is_can(Rows, 1, []),
			vaccineHPV_push:send(InfoList),
			io:format("MODULE:[~p]-LIINE:[~p] |  :~p~n", [?MODULE, ?LINE, {length(Rows)}]);
		Err ->
			io:format("MODULE:[~p]-LIINE:[~p] | Err:~p~n", [?MODULE, ?LINE, {Err}]),
			Err
	end.

%% -----------------------------------------------------------------
%% Description: 判断是否可预约
%% Inputs:
%% Returns:
%% -----------------------------------------------------------------
is_can_subscribe(Id, DepaCode, VaccineCode, LinkManId, Cookie, Tk) ->
	timer:sleep(15),
%%	 io:format("[~p] [~p] | Id, DepaCode, VaccineCode, LinkManId, Cookie, Tk:~p~n", [?MODULE, ?LINE, {Id, DepaCode, VaccineCode, LinkManId, Cookie, Tk}]),
	Header =
		[
			?HEAD_ACCEPT,
			?HEAD_USER_AGENT,
			{"Cookie", Cookie},
			{"tk", Tk}
		],
	Request = {[?URL_IS_CAN_SUBSCRIBE,
		"?id=", Id, "&depaCode=", DepaCode, "&vaccineCode=", VaccineCode, "&linkmanId=", LinkManId], Header},

	HttpOptions =
		[
			{timeout, timer:seconds(3)}%% 请求超时3s
		],
	Options =
		[
			{sync, true},
			{full_result, false},
			{body_format, binary}
		],
	{ok, Response} = httpc:request(get, Request, HttpOptions, Options),
	case parse_body(Response) of
		{ok, Data} ->
			TypeCode = maps:get(<<"typeCode">>, Data),
			TypeCode == ?TYPECODE_CANSUBSCRIBE;
		Err ->
			Err
	end.

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

	HttpOptions =
		[
			{timeout, timer:seconds(3)}%% 请求超时3s
		],
	Options =
		[
			{sync, true},
			{full_result, false},
			{body_format, binary}
		],
	{ok, Response} = httpc:request(get, Request, HttpOptions, Options),
	case parse_body(Response) of
		{err_lose, _} ->
			err;
		_ ->
			ok
	end.

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
	{err, Data}.

loop_check_is_can([#{<<"depaVaccId">> := DepaVaccId, <<"code">> := DepaCode, <<"vaccineCode">> := VaccineCode} = H | T], Index, R) ->
	DepaVaccId1 = integer_to_list(DepaVaccId),
	case is_can_subscribe(DepaVaccId1, DepaCode, VaccineCode, ?LINKMANID, ?COOKIE, ?TK) of
		true ->
%%				#{<<"address">> := Address, <<"vaccineName">> := Name} = H,
			#{<<"imgUrl">> := ImgUrl, <<"name">> := Name, <<"vaccineName">> := Desc} = H,
			 io:format("MODULE:[~p]-LIINE:[~p] | DepaVaccId:~p~n", [?MODULE, ?LINE, {DepaVaccId}]),
			loop_check_is_can(T, Index + 1, [{ImgUrl, Name, Desc} | R]);
		false ->
			loop_check_is_can(T, Index + 1, R);
		Err ->
			Err
	end;
loop_check_is_can([], _Index, R) ->
	R.

check_body_code(#{<<"code">> := <<"0000">>}) ->
	ok;
check_body_code(#{<<"code">> := <<"1001">>}) ->
	{err_lose, <<"cookie lose efficacy">>};
check_body_code(#{<<"code">> := Code}) ->
	{err_code, Code}.

