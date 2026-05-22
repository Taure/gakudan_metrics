-module(gakudan_metrics_definitions).
-moduledoc """
Declares the Prometheus metrics that `gakudan_metrics_handlers` updates from
gakudan telemetry events.

High-cardinality keys (run_id, turn) deliberately stay out of metric labels.
They are still available on the raw telemetry events for tracing or audit
sinks that need them.
""".

-export([declare/0]).

-define(RUN_BUCKETS, [0.1, 0.5, 1, 5, 10, 30, 60, 300, 600, 1800]).
-define(TURN_BUCKETS, [0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30]).
-define(LLM_BUCKETS, [0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60]).
-define(TOOL_BUCKETS, [0.005, 0.01, 0.05, 0.1, 0.5, 1, 5, 10]).
-define(ROUTER_BUCKETS, [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1]).
-define(TURN_COUNT_BUCKETS, [1, 2, 4, 8, 16, 32, 64, 128]).

-spec declare() -> ok.
declare() ->
    counters(),
    histograms(),
    ok.

counters() ->
    prometheus_counter:declare([
        {name, gakudan_runs_started_total},
        {help, "Total gakudan runs started."},
        {labels, [router, llm_backend]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_runs_stopped_total},
        {help, "Total gakudan runs stopped, by termination reason."},
        {labels, [reason]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_turns_total},
        {help, "Total agent turns, by agent and outcome."},
        {labels, [agent_id, outcome]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_llm_requests_total},
        {help, "Total LLM requests completed."},
        {labels, [backend, model, outcome]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_llm_tokens_input_total},
        {help, "Total input tokens consumed by LLM requests."},
        {labels, [backend, model]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_llm_tokens_output_total},
        {help, "Total output tokens produced by LLM requests."},
        {labels, [backend, model]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_llm_exceptions_total},
        {help, "Total exceptions raised inside an LLM request."},
        {labels, [backend, model]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_tool_runs_total},
        {help, "Total tool invocations."},
        {labels, [tool, outcome]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_tool_exceptions_total},
        {help, "Total exceptions raised inside a tool invocation."},
        {labels, [tool]}
    ]),
    prometheus_counter:declare([
        {name, gakudan_router_decisions_total},
        {help, "Total router decisions."},
        {labels, [router, decision_type]}
    ]),
    ok.

histograms() ->
    prometheus_histogram:declare([
        {name, gakudan_run_duration_seconds},
        {help, "Wall-clock duration of a gakudan run."},
        {labels, [reason]},
        {buckets, ?RUN_BUCKETS}
    ]),
    prometheus_histogram:declare([
        {name, gakudan_run_turns_count},
        {help, "Number of agent turns per run."},
        {labels, [reason]},
        {buckets, ?TURN_COUNT_BUCKETS}
    ]),
    prometheus_histogram:declare([
        {name, gakudan_turn_duration_seconds},
        {help, "Wall-clock duration of a single agent turn."},
        {labels, [agent_id, outcome]},
        {buckets, ?TURN_BUCKETS}
    ]),
    prometheus_histogram:declare([
        {name, gakudan_llm_request_duration_seconds},
        {help, "Wall-clock duration of an LLM request."},
        {labels, [backend, model, outcome]},
        {buckets, ?LLM_BUCKETS}
    ]),
    prometheus_histogram:declare([
        {name, gakudan_tool_run_duration_seconds},
        {help, "Wall-clock duration of a single tool invocation."},
        {labels, [tool, outcome]},
        {buckets, ?TOOL_BUCKETS}
    ]),
    prometheus_histogram:declare([
        {name, gakudan_router_decide_duration_seconds},
        {help, "Wall-clock duration of a router decision."},
        {labels, [router]},
        {buckets, ?ROUTER_BUCKETS}
    ]),
    ok.
