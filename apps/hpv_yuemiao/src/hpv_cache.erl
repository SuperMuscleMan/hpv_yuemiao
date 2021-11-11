-module(hpv_cache).
%%%=======================STATEMENT====================
-description("hpv_cookie").
-copyright('').
-author("wmh, SuperMuscleMan@outlook.com").
%%%=======================EXPORT=======================
-export([get_tk/0, set_tk/1, get_cookie/0, set_cookie/1, parse_cookie/1, set_departments/1, get_departments/0,
	get_card_no/0, set_card_no/1, set_linkmanid/1, get_linkmanid/0, set_is_continue/0, get_is_continue/0,
	set_next_few_months/1, get_next_few_months/0, get_cookie_geting/0, set_cookie_geting/1, get_delay/0,
	set_total/1, get_total/0, set_departments2/2]).
%%%=======================INCLUDE======================

%%%=======================RECORD=======================

%%%=======================DEFINE=======================
-define(RegExpParse_TK, "tk\:\s(.+)").
-define(RegExpParse_COOKIE, "Cookie\:\s(.+)").
-define(RegExpOptions, [{capture, [1], list}]).
%%%=================EXPORTED FUNCTIONS=================

%% -----------------------------------------------------------------
%% Func: 
%% Description: 
%% Returns: 
%% -----------------------------------------------------------------
set_cookie(Cookie) ->
	wx_cfg:set(?MODULE, cookie, Cookie).
get_cookie() ->
	wx_cfg:get(?MODULE, cookie).

set_tk(Tk) ->
	wx_cfg:set(?MODULE, tk, Tk).
get_tk() ->
	wx_cfg:get(?MODULE, tk).

parse_cookie(Str) ->
	{match, [Tk]} = re:run(Str, ?RegExpParse_TK, ?RegExpOptions),
	{match, [Cookie]} = re:run(Str, ?RegExpParse_COOKIE, ?RegExpOptions),
	set_cookie(Cookie),
	set_tk(Tk).

set_departments(List) ->
	wx_cfg:set(?MODULE, departments, List).
get_departments() ->
	wx_cfg:get(?MODULE, departments).

%% 再次存储department数据（用于比较是否新上的
set_departments2([#{<<"code">> := Code} = H|T], R)->
	case wx_cfg:get(departments, Code) of
		 none ->
			 wx_cfg:set(departments, Code, H),
			 set_departments2(T, [H|R]);
		_->
			set_departments2(T, R)
end;
set_departments2([], R)->
	R.

	

set_linkmanid(UserId) ->
	wx_cfg:set(?MODULE, linkmanid, UserId).
get_linkmanid() ->
	case wx_cfg:get(?MODULE, linkmanid) of
		none ->
			{CardNo, LinkManId} = vaccineHPV:get_find_by_user_id(get_cookie(), get_tk()),
			set_card_no(CardNo),
			set_linkmanid(LinkManId),
			LinkManId;
		V ->
			V
	end.

set_card_no(CardNo) ->
	wx_cfg:set(?MODULE, card_no, CardNo).
get_card_no() ->
	case wx_cfg:get(?MODULE, card_no) of
		none ->
			{CardNo, LinkManId} = vaccineHPV:get_find_by_user_id(get_cookie(), get_tk()),
			set_card_no(CardNo),
			set_linkmanid(LinkManId),
			CardNo;
		V ->
			V
	end.

get_is_continue()->
	wx_cfg:get(?MODULE, is_continue).

set_is_continue()->
	wx_cfg:set(?MODULE, is_continue, false).

get_next_few_months()->
	wx_cfg:get(?MODULE, get_next_few_months).
set_next_few_months(D)->
	wx_cfg:set(?MODULE, get_next_few_months, D).

set_cookie_geting(Expire)->
	wx_cfg:set(?MODULE, cookie_geting, Expire).
get_cookie_geting()->
	wx_cfg:get(?MODULE, cookie_geting).

get_delay() ->
	case wx_cfg:get(?MODULE, get_delay) of
		none ->
			10;
		V ->
			V
	end.

set_total(T)->
	wx_cfg:set(?MODULE, total, T).
get_total() ->
	case wx_cfg:get(?MODULE, total) of
		none ->
			60;
		V ->
			V
	end.
%==========================DEFINE=======================