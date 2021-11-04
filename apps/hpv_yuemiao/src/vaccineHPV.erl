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
-export([get_departments/0]).
%%%=======================INCLUDE======================
-include("vaccineHPV.hrl").
%%%=======================RECORD=======================

%%%=======================DEFINE=======================
-define(LINKMANID, <<"">>).
-define(COOKIE, "UM_distinctid=17ce613993c34de-07f076f18a3998-61263e23-384000-17ce63993c4384; CNZZDATA1261985103=529582824-1635949424-%7C1635949424; _xzkj_=wxtoken:829d6a86994947f5f09f05d6be6a0cb3_b840a63b7ddc323b5f0e69e3564c795d; _xxhm_=%7B%22id%22%3A8578590%2C%22mobile%22%3A%2218782052254%22%2C%22nickName%22%3A%22%EF%BB%BF%EF%BB%BF%22%2C%22headerImg%22%3A%22http%3A%2F%2Fthirdwx.qlogo.cn%2Fmmopen%2FQ3auHgzwzM7CZaQRs8UkbMLsegFWFwrkiclQW9AwdLBYqba25boez0XJ8RdJ2xHSok23iauJ38d1wg1w6icktmwW7kRKCIghia91lsibGv9n1J24%2F132%22%2C%22regionCode%22%3A%22510107%22%2C%22name%22%3A%22%E5%BE%90*%22%2C%22uFrom%22%3A%22depa_vacc_detail%22%2C%22wxSubscribed%22%3A1%2C%22birthday%22%3A%221995-11-01+00%3A00%3A00%22%2C%22sex%22%3A2%2C%22hasPassword%22%3Afalse%2C%22birthdayStr%22%3A%221995-11-01%22%7D").
-define(TK, "wxtoken:829d6a869914947f5f09f05d6be6a0cb3_b840a63b7ddc323b5f0e69e3564c795d").
%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Description: 获取信息列表
%% Inputs:
%% Returns: 
%% -----------------------------------------------------------------
get_departments() ->
	Header = [?HEAD_ACCEPT, ?HEAD_USER_AGENT],
	ContentType = ?HEAD_CONTENT_TYPE,
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
	{ok, Response} = httpc:request(?METHOD_GET_DEPARTMENTS, Request, HttpOptions, Options),
	case parse_body(Response) of
		{ok, Data} ->
			Rows = maps:get(<<"rows">>, Data),
			loop_check_is_can(Rows, 1, []);
		Err ->
	ok
	end.

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
	Data = parse_body(Response),
	TypeCode = maps:get(<<"typeCode">>, Data),
	TypeCode == ?TYPECODE_CANSUBSCRIBE.


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
	R1 =
		case is_can_subscribe(integer_to_list(DepaVaccId), DepaCode, VaccineCode, ?LINKMANID, ?COOKIE, ?TK) of
			true ->
				#{<<"address">> := Address, <<"vaccineName">> := Name} = H,
				[{Index, Address, Name} | R];
			_ ->
				R
		end,
	loop_check_is_can(T, Index + 1, R1);
loop_check_is_can([], _Index, R) ->
	R.

check_body_code(#{<<"code">> := <<"0000">>}) ->
	ok;
check_body_code(#{<<"code">> := <<"1001">>}) ->
	<<"cookie lose efficacy">>;
check_body_code(#{<<"code">> := Code}) ->
	{err_code, Code}.

