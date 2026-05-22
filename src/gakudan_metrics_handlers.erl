-module(gakudan_metrics_handlers).
-moduledoc """
`:telemetry` handlers that translate gakudan events into Prometheus updates.

Attached by `gakudan_metrics:setup/0`. Idempotent: attaching the same
`HandlerId` twice is a no-op.
""".

-export([attach/1, detach/1, handle/4]).

-define(EVENTS, [
    [gakudan, run, start],
    [gakudan, run, stop],
    [gakudan, turn, stop],
    [gakudan, llm, request, stop],
    [gakudan, llm, request, exception],
    [gakudan, tool, run, stop],
    [gakudan, tool, run, exception],
    [gakudan, router, decide, stop]
]).

-spec attach(term()) -> ok.
attach(HandlerId) ->
    case telemetry:attach_many(HandlerId, ?EVENTS, fun ?MODULE:handle/4, []) of
        ok -> ok;
        {error, already_exists} -> ok
    end.

-spec detach(term()) -> ok.
detach(HandlerId) ->
    _ = telemetry:detach(HandlerId),
    ok.

-spec handle(telemetry:event_name(), map(), map(), term()) -> ok.
handle([gakudan, run, start], _Measurements, Meta, _Config) ->
    Router = label(maps:get(router, Meta, undefined)),
    Backend = label(maps:get(llm_backend, Meta, undefined)),
    prometheus_counter:inc(gakudan_runs_started_total, [Router, Backend]),
    ok;
handle([gakudan, run, stop], Measurements, Meta, _Config) ->
    Reason = reason_label(maps:get(reason, Meta, undefined)),
    prometheus_counter:inc(gakudan_runs_stopped_total, [Reason]),
    prometheus_histogram:observe(
        gakudan_run_duration_seconds,
        [Reason],
        native_to_seconds(maps:get(duration, Measurements, 0))
    ),
    prometheus_histogram:observe(
        gakudan_run_turns_count, [Reason], maps:get(turns, Measurements, 0)
    ),
    ok;
handle([gakudan, turn, stop], Measurements, Meta, _Config) ->
    AgentId = label(maps:get(agent_id, Meta, undefined)),
    Outcome = label(maps:get(outcome, Meta, undefined)),
    prometheus_counter:inc(gakudan_turns_total, [AgentId, Outcome]),
    prometheus_histogram:observe(
        gakudan_turn_duration_seconds,
        [AgentId, Outcome],
        native_to_seconds(maps:get(duration, Measurements, 0))
    ),
    ok;
handle([gakudan, llm, request, stop], Measurements, Meta, _Config) ->
    Backend = label(maps:get(backend, Meta, undefined)),
    Model = label(maps:get(model, Meta, undefined)),
    Outcome = label(maps:get(outcome, Meta, undefined)),
    prometheus_counter:inc(gakudan_llm_requests_total, [Backend, Model, Outcome]),
    prometheus_histogram:observe(
        gakudan_llm_request_duration_seconds,
        [Backend, Model, Outcome],
        native_to_seconds(maps:get(duration, Measurements, 0))
    ),
    inc_by(
        gakudan_llm_tokens_input_total,
        [Backend, Model],
        maps:get(tokens_in, Measurements, 0)
    ),
    inc_by(
        gakudan_llm_tokens_output_total,
        [Backend, Model],
        maps:get(tokens_out, Measurements, 0)
    ),
    ok;
handle([gakudan, llm, request, exception], _Measurements, Meta, _Config) ->
    Backend = label(maps:get(backend, Meta, undefined)),
    Model = label(maps:get(model, Meta, undefined)),
    prometheus_counter:inc(gakudan_llm_exceptions_total, [Backend, Model]),
    ok;
handle([gakudan, tool, run, stop], Measurements, Meta, _Config) ->
    Tool = label(maps:get(tool, Meta, undefined)),
    Outcome = label(maps:get(outcome, Meta, undefined)),
    prometheus_counter:inc(gakudan_tool_runs_total, [Tool, Outcome]),
    prometheus_histogram:observe(
        gakudan_tool_run_duration_seconds,
        [Tool, Outcome],
        native_to_seconds(maps:get(duration, Measurements, 0))
    ),
    ok;
handle([gakudan, tool, run, exception], _Measurements, Meta, _Config) ->
    Tool = label(maps:get(tool, Meta, undefined)),
    prometheus_counter:inc(gakudan_tool_exceptions_total, [Tool]),
    ok;
handle([gakudan, router, decide, stop], Measurements, Meta, _Config) ->
    Router = label(maps:get(router, Meta, undefined)),
    Decision = decision_label(maps:get(decision, Meta, undefined)),
    prometheus_counter:inc(gakudan_router_decisions_total, [Router, Decision]),
    prometheus_histogram:observe(
        gakudan_router_decide_duration_seconds,
        [Router],
        native_to_seconds(maps:get(duration, Measurements, 0))
    ),
    ok;
handle(_Event, _Measurements, _Meta, _Config) ->
    ok.

inc_by(_Metric, _Labels, 0) ->
    ok;
inc_by(Metric, Labels, N) when is_integer(N), N > 0 ->
    prometheus_counter:inc(Metric, Labels, N);
inc_by(_Metric, _Labels, _) ->
    ok.

native_to_seconds(N) when is_integer(N), N >= 0 ->
    N / erlang:convert_time_unit(1, second, native);
native_to_seconds(_) ->
    0.0.

decision_label({next, _}) -> ~"next";
decision_label(done) -> ~"done";
decision_label(_) -> ~"unknown".

reason_label(normal) -> ~"normal";
reason_label(shutdown) -> ~"shutdown";
reason_label({shutdown, _}) -> ~"shutdown";
reason_label(undefined) -> ~"unknown";
reason_label(_) -> ~"crash".

label(undefined) -> ~"unknown";
label(A) when is_atom(A) -> atom_to_binary(A);
label(B) when is_binary(B) -> B;
label(I) when is_integer(I) -> integer_to_binary(I);
label(Term) -> iolist_to_binary(io_lib:format("~p", [Term])).
