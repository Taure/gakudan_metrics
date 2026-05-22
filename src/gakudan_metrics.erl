-module(gakudan_metrics).
-moduledoc """
Prometheus exporter for `gakudan`.

Declares Prometheus metrics for every event in the gakudan telemetry surface
(see [ADR 0001](https://github.com/Taure/gakudan/blob/main/docs/adr/0001-telemetry-events.md))
and attaches `:telemetry` handlers that translate events into counter / sum /
histogram updates.

Quickstart:

```erlang
{ok, _} = application:ensure_all_started(gakudan_metrics),
{ok, _} = gakudan_metrics:start_listener(9568).
```

Point Prometheus at `:9568/metrics`. Import `priv/grafana/gakudan.json`.

To mount the scrape handler on an existing Cowboy listener instead of
standing up your own:

```erlang
Routes = [
    {"/metrics", prometheus_cowboy2_handler, []},
    %% ...your other routes
].
```
""".

-export([setup/0, start_listener/1, start_listener/2, stop_listener/0]).

-define(LISTENER, gakudan_metrics_listener).
-define(HANDLER_ID, gakudan_metrics_handler).

-doc "Declare metrics and attach telemetry handlers. Idempotent.".
-spec setup() -> ok.
setup() ->
    ok = gakudan_metrics_definitions:declare(),
    ok = gakudan_metrics_handlers:attach(?HANDLER_ID),
    ok.

-doc "Start a standalone Cowboy listener on `Port` serving `/metrics`.".
-spec start_listener(inet:port_number()) -> {ok, pid()} | {error, term()}.
start_listener(Port) ->
    start_listener(Port, #{}).

-doc "Like `start_listener/1` with extra Cowboy `protocol_opts` overrides.".
-spec start_listener(inet:port_number(), map()) -> {ok, pid()} | {error, term()}.
start_listener(Port, ExtraProtoOpts) ->
    Dispatch = cowboy_router:compile([
        {'_', [{"/metrics", prometheus_cowboy2_handler, []}]}
    ]),
    ProtoOpts = maps:merge(#{env => #{dispatch => Dispatch}}, ExtraProtoOpts),
    cowboy:start_clear(?LISTENER, [{port, Port}], ProtoOpts).

-doc "Stop the standalone listener started by `start_listener/1,2`.".
-spec stop_listener() -> ok | {error, not_found}.
stop_listener() ->
    cowboy:stop_listener(?LISTENER).
