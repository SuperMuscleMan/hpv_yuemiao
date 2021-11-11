-module(vaccineHPV_push).
%%%=======================STATEMENT====================
-description("vaccineHPV_push").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([send/1, send_success/1, send_log/1]).
%%%=======================INCLUDE======================
-include("vaccineHPV.hrl").
-include_lib("wx_log_library/include/wx_log.hrl").
%%%=======================RECORD=======================

%%%=======================DEFINE=======================
-define(URL_ITEM(Id), <<"https://wx.scmttec.com/base/departmentVaccine/item.do?isShowDescribtion=true&showOthers=true&id=", Id/binary>>).
-define(URL_INDEX, <<"https://wx.scmttec.com/index.html ">>).

-define(APPTOKEN, <<"AT_MyJXgVzfsz15NLhaUBdi9w56kcTsPwbq">>).
-define(WEBHOOK_COMPANY, "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=c752f5d2-104c-4565-a2f0-b20d95bea044").
-define(WEBHOOK_SCHOOL, "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=f914111d-050e-4ef9-9279-616b2b363972").

-define(COUNTENT_TYPE_MARKDOWN, 3).

-define(PUSH_NUM, 8).
%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Func: 
%% Description: 
%% Returns: 
%% -----------------------------------------------------------------
send([]) ->
	ok;
send([H1, H2, H3, H4, H5, H6, H7, H8 | T]) ->
	try
		send_([H1, H2, H3, H4, H5, H6, H7, H8])
	catch
		E1:E2:E3 ->
			?ERR(["Push message failed.", E1, E2, E3])
	end,
	send(T);
send(List) ->
	send_(List).
send_(List) ->
	Countent = pack_new_item(List, []),
	Body = pack_news(Countent),
	Header = [],
	ContentType = ?HEAD_CONTENT_TYPE_JSON,
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
	Request = {?WEBHOOK_SCHOOL, Header, ContentType, Body},
	{ok, _Response} = httpc:request(post, Request, HttpOptions, Options).

send_success(Item) ->
	Content = pack_markdown_content(Item),
	Body = pack_markdown(Content),
	Header = [],
	ContentType = ?HEAD_CONTENT_TYPE_JSON,
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
	Request = {?WEBHOOK_SCHOOL, Header, ContentType, Body},
	{ok, Response} = httpc:request(post, Request, HttpOptions, Options),
	Json = parse_response(Response),
	check_response(Json).

send_log(Content) ->
	Body = pack_markdown(Content),
	Header = [],
	ContentType = ?HEAD_CONTENT_TYPE_JSON,
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
	Request = {?WEBHOOK_COMPANY, Header, ContentType, Body},
	{ok, {200, Response}} = httpc:request(post, Request, HttpOptions, Options),
	Json = jsx:decode(Response),
	case maps:get(<<"errcode">>, Json) of
		0 ->
			ok;
		_ ->
			?ERR(["Error push log.", Response])
	end.

%==========================DEFINE=======================
pack_new_item([{ImgUrl, Name, Desc} | T], R) ->
	Item =
		[
			{<<"title">>, Name},
			{<<"description">>, Desc},
			{<<"url">>, ?URL_INDEX},
			{<<"picurl">>, ImgUrl}
		],
	pack_new_item(T, [Item | R]);
pack_new_item([], R) ->
	R.

pack_news(Content) ->
	Body =
		[
			{<<"msgtype">>, <<"news">>},
			{<<"news">>,
				[{<<"articles">>, Content}]
			}
		],
	jsx:encode(Body).

pack_markdown_content(Item) ->
	#{<<"name">> := Name, <<"vaccineName">> := Desc} = Item,
	unicode:characters_to_binary([
		"## 预约成功！", $\r, $\n,
		"### 社区名称：", Name, $\r, $\n,
		"### 详情：", Desc, $\r, $\n
	]).

pack_markdown(Content) ->
	Body =
		[
			{<<"msgtype">>, <<"markdown">>},
			{<<"markdown">>,
				[{<<"content">>, Content}]
			}
		],
	jsx:encode(Body).

parse_response({200, Binary}) ->
	jsx:decode(Binary);
parse_response(Data) ->
	{err_parse, Data}.

%% 1000表示推送成功
check_response(#{<<"code">> := 1000}) ->
	ok;
check_response(Data) ->
	{err_check, Data}.