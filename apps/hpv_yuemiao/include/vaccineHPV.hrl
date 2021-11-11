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

-define(HEAD_CONTENT_TYPE_URLENCODED,"application/x-www-form-urlencoded").
-define(HEAD_CONTENT_TYPE_JSON, "application/json").

%% yuemiao URL
-define(URL_GET_NOT_READ, "https://wx.scmttec.com/message/notice/getNotReadNoticeNum.do"). %% 获取未读通知（用于判断cookie是否有效
-define(URL_FINDBYUSERID, "https://wx.scmttec.com/order/linkman/findByUserId.do").%% 获取用户信息
-define(URL_NOW, "https://wx.scmttec.com/base//time/now.do").%% 获取服务器时间

-define(URL_GET_DEPARTMENTS, "https://wx.scmttec.com/department/department/getDepartments.do").	%% 1、获取信息列表（无需cookie
-define(URL_IS_CAN_SUBSCRIBE, "https://wx.scmttec.com/subscribe/subscribe/isCanSubscribe.do"). %% 2、获取状态状态
-define(URL_DELAYSUBSCRIBE, "https://wx.scmttec.com/passport/register/subscibe.do").%% 3、订阅（订阅后，来苗时公众号通知

-define(URL_WORKDAYSBYMONTH, "https://wx.scmttec.com/order/subscribe/workDaysByMonth.do").%% 4、订阅第一步：获取可接种日期列表
-define(URL_FINDSUBSCRIBEAMOUNTBYDAYS, "https://wx.scmttec.com/subscribe/subscribe/findSubscribeAmountByDays.do"). %% 4、订阅第二步：获取可接种日期列表是否能能预约 maxSub=0不能
-define(URL_DEPARTMENTWORKTIMES2, "https://wx.scmttec.com/subscribe/subscribe/departmentWorkTimes2.do"). %% 4、订阅第三步：获取指定日期当天的时间段。 maxSub值表示剩余数量
-define(URL_ADD, "https://wx.scmttec.com/subscribe/subscribe/add.do").%% 4、订阅第四步：发送订单



-define(TYPECODE_CANSUBSCRIBE, 1).%% 可预约
-define(TYPECODE_DELAYSUBSCRIBE, 2).%% 可订阅
-define(TYPECODE_ALREDY, 3).	%% 已订阅
-define(TYPECODE_NOTCAN, 4).	%% 不可订阅

