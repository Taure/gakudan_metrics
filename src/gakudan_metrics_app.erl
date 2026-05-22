-module(gakudan_metrics_app).
-moduledoc false.

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    case application:get_env(gakudan_metrics, auto_setup, true) of
        true -> ok = gakudan_metrics:setup();
        false -> ok
    end,
    gakudan_metrics_sup:start_link().

stop(_State) ->
    ok.
