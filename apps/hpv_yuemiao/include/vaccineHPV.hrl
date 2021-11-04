%%%-------------------------------------------------------------------
%%% @author WeiMengHuan
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 11月 2021 20:54
%%%-------------------------------------------------------------------

-define(HEAD_USER_AGENT, {"User_Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36 NetType/WIFI MicroMessenger/7.0.20.1781(0x6700143B) WindowsWechat(0x63040026)"}).
-define(HEAD_ACCEPT, {"Accept", "application/json, text/plain, */*"}).
-define(HEAD_CONTENT_TYPE,"application/x-www-form-urlencoded").

-define(METHOD_GET_DEPARTMENTS, post).
-define(URL_GET_DEPARTMENTS, "https://wx.scmttec.com/department/department/getDepartments.do").	%% 获取信息列表
-define(URL_IS_CAN_SUBSCRIBE, "https://wx.scmttec.com/subscribe/subscribe/isCanSubscribe.do"). %% 是否预约状态（需要cookie

-define(BODY_GET_DEPARTMENTS, <<"offset=0&limit=100&regionCode=5101&isOpen=1&sortType=1&customId=52">>).%%


-define(TYPECODE_CANSUBSCRIBE, 1).%% 可预约
-define(TYPECODE_DELAYSUBSCRIBE, 2).%% 可订阅
-define(TYPECODE_ALREDY, 3).	%% 已订阅
-define(TYPECODE_NOTCAN, 4).	%% 不可订阅

