-module(gakudan_metrics_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([
    setup_is_idempotent/1,
    run_start_increments_counter/1,
    llm_request_records_tokens_and_duration/1,
    tool_run_records_outcome/1,
    router_decide_records_decision/1,
    scrape_returns_prometheus_text/1
]).

all() ->
    [
        setup_is_idempotent,
        run_start_increments_counter,
        llm_request_records_tokens_and_duration,
        tool_run_records_outcome,
        router_decide_records_decision,
        scrape_returns_prometheus_text
    ].

init_per_suite(Config) ->
    application:set_env(gakudan_metrics, auto_setup, false),
    {ok, _} = application:ensure_all_started(gakudan_metrics),
    ok = gakudan_metrics:setup(),
    Config.

end_per_suite(_Config) ->
    ok = application:stop(gakudan_metrics),
    ok.

setup_is_idempotent(_Config) ->
    ok = gakudan_metrics:setup(),
    ok = gakudan_metrics:setup(),
    ok.

run_start_increments_counter(_Config) ->
    Before = counter_value(gakudan_runs_started_total, [~"round_robin", ~"stub"]),
    telemetry:execute(
        [gakudan, run, start],
        #{system_time => erlang:system_time()},
        #{
            run_id => ~"r1",
            agents => [a, b],
            router => round_robin,
            llm_backend => stub,
            max_turns => 4
        }
    ),
    After = counter_value(gakudan_runs_started_total, [~"round_robin", ~"stub"]),
    ?assertEqual(Before + 1, After).

llm_request_records_tokens_and_duration(_Config) ->
    InBefore = counter_value(gakudan_llm_tokens_input_total, [~"anthropic", ~"claude-sonnet-4-6"]),
    OutBefore = counter_value(gakudan_llm_tokens_output_total, [~"anthropic", ~"claude-sonnet-4-6"]),
    ReqBefore = counter_value(gakudan_llm_requests_total, [
        ~"anthropic", ~"claude-sonnet-4-6", ~"ok"
    ]),
    telemetry:execute(
        [gakudan, llm, request, stop],
        #{
            duration => erlang:convert_time_unit(150, millisecond, native),
            tokens_in => 42,
            tokens_out => 7
        },
        #{
            run_id => ~"r1",
            agent_id => coder,
            backend => anthropic,
            model => ~"claude-sonnet-4-6",
            outcome => ok
        }
    ),
    ?assertEqual(
        InBefore + 42,
        counter_value(gakudan_llm_tokens_input_total, [~"anthropic", ~"claude-sonnet-4-6"])
    ),
    ?assertEqual(
        OutBefore + 7,
        counter_value(gakudan_llm_tokens_output_total, [~"anthropic", ~"claude-sonnet-4-6"])
    ),
    ?assertEqual(
        ReqBefore + 1,
        counter_value(gakudan_llm_requests_total, [~"anthropic", ~"claude-sonnet-4-6", ~"ok"])
    ).

tool_run_records_outcome(_Config) ->
    Before = counter_value(gakudan_tool_runs_total, [~"echo_tool", ~"ok"]),
    telemetry:execute(
        [gakudan, tool, run, stop],
        #{duration => erlang:convert_time_unit(5, millisecond, native)},
        #{run_id => ~"r1", agent_id => coder, tool => ~"echo_tool", outcome => ok}
    ),
    ?assertEqual(Before + 1, counter_value(gakudan_tool_runs_total, [~"echo_tool", ~"ok"])).

router_decide_records_decision(_Config) ->
    Before = counter_value(gakudan_router_decisions_total, [~"round_robin", ~"next"]),
    telemetry:execute(
        [gakudan, router, decide, stop],
        #{duration => 1000},
        #{run_id => ~"r1", router => round_robin, decision => {next, coder}}
    ),
    ?assertEqual(
        Before + 1,
        counter_value(gakudan_router_decisions_total, [~"round_robin", ~"next"])
    ).

scrape_returns_prometheus_text(_Config) ->
    Body = iolist_to_binary(prometheus_text_format:format()),
    ?assert(binary:match(Body, ~"gakudan_runs_started_total") =/= nomatch),
    ?assert(binary:match(Body, ~"gakudan_llm_requests_total") =/= nomatch),
    ?assert(binary:match(Body, ~"gakudan_llm_tokens_input_total") =/= nomatch),
    ?assert(binary:match(Body, ~"# HELP gakudan_") =/= nomatch),
    ?assert(binary:match(Body, ~"# TYPE gakudan_") =/= nomatch).

counter_value(Metric, Labels) ->
    case prometheus_counter:value(Metric, Labels) of
        undefined -> 0;
        V when is_number(V) -> V
    end.
