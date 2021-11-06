-module(vaccineHPV_push).
%%%=======================STATEMENT====================
-description("vaccineHPV_push").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([send/1]).
%%%=======================INCLUDE======================
-include("vaccineHPV.hrl").
%%%=======================RECORD=======================

%%%=======================DEFINE=======================
-define(TITLE, "有可订阅社区啦！").
%%-define(URL_PUSH, "https://sctapi.ftqq.com/SCT91235TJxFG5lhFO6Y1TZLU5zdGLmGd.send?title=有可订阅社区啦！&desp=messagecontent").
%%-define(URL_PUSH, "http://wxpusher.zjiecode.com/api/send/message").
-define(URL_PUSH_ROBOT, "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=c752f5d2-104c-4565-a2f0-b20d95bea044").
-define(URL_ITEM(Id), <<"https://wx.scmttec.com/base/departmentVaccine/item.do?isShowDescribtion=true&showOthers=true&id=", Id/binary>>).
-define(URL_INDEX, <<"https://wx.scmttec.com/index.html ">>).

-define(APPTOKEN, <<"AT_MyJXgVzfsz15NLhaUBdi9w56kcTsPwbq">>).
-define(WEBHOOK, "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=c752f5d2-104c-4565-a2f0-b20d95bea044").

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
	    E1:E2:E3  ->
			ok
%%			 io:format("MODULE:[~p]-LIINE:[~p] | E1,E2,E3:~p~n", [?MODULE, ?LINE, {E1,E2,E3}])
	end ,
	send(T);
send(List) ->
	send_(List).
send_(List) ->
	Countent = pack_item(List, []),
%%	Body = pack_body(Countent, ?COUNTENT_TYPE_MARKDOWN, [<<"UID_lZoKU72YsTqSgmd4rpl98Xe5kOBf">>]),
	Body = pack_body(Countent),
%%	io:format("MODULE:[~p]-LIINE:[~p] | Body:~p~n", [?MODULE, ?LINE, {Body}]),
%%	Header = [?HEAD_ACCEPT, ?HEAD_USER_AGENT],
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
	Request = {?URL_PUSH_ROBOT, Header, ContentType, Body},
	{ok, Response} = httpc:request(post, Request, HttpOptions, Options),
	Json = parse_response(Response),
	ok = check_response(Json).
%==========================DEFINE=======================
pack_item([{ImgUrl, Name, Desc} | T], R) ->
	Item =
		[
			{<<"title">>, Name},
			{<<"description">>, Desc},
			{<<"url">>, ?URL_INDEX},
			{<<"picurl">>, ImgUrl}
		],
	pack_item(T, [Item |R]);
pack_item([], R) ->
	R.

pack_body(Content) ->
	Body =
		[
			{<<"msgtype">>, <<"news">>},
			{<<"news">>,
				[{<<"articles">>, Content}]
			}
		],
	jsx:encode(Body).

parse_response({200, Binary}) ->
	jsx:decode(Binary);
parse_response(Data) ->
	{err_parse, Data}.

%% 1000表示推送成功
check_response(#{<<"code">> := 1000})->
	ok;
check_response(Data)->
	{err_check, Data}.