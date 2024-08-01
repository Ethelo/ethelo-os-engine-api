--
-- PostgreSQL database dump
--

-- Dumped from database version 13.12
-- Dumped by pg_dump version 13.12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: constraint_operator; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.constraint_operator AS ENUM (
    'equal_to',
    'less_than_or_equal_to',
    'greater_than_or_equal_to',
    'between'
);


--
-- Name: detail_format; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.detail_format AS ENUM (
    'string',
    'integer',
    'float',
    'boolean',
    'datetime'
);



--
-- Name: scoring_mode; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.scoring_mode AS ENUM (
    'none',
    'rectangle',
    'triangle'
);


--
-- Name: variable_method; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.variable_method AS ENUM (
    'count_selected',
    'count_all',
    'sum_selected',
    'mean_selected',
    'sum_all',
    'mean_all'
);


--
-- Name: voting_style; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.voting_style AS ENUM (
    'one',
    'range'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bin_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bin_votes (
    id integer NOT NULL,
    bin integer NOT NULL,
    decision_id integer NOT NULL,
    participant_id integer NOT NULL,
    criteria_id integer NOT NULL,
    option_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bin_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bin_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bin_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bin_votes_id_seq OWNED BY public.bin_votes.id;


--
-- Name: cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cache (
    id integer NOT NULL,
    key character varying(255) NOT NULL,
    value text NOT NULL,
    decision_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cache_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cache_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cache_id_seq OWNED BY public.cache.id;


--
-- Name: calculation_variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calculation_variables (
    calculation_id integer NOT NULL,
    variable_id integer NOT NULL
);


--
-- Name: calculations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calculations (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    expression text NOT NULL,
    display_hint character varying(255),
    public boolean DEFAULT false NOT NULL,
    decision_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    personal_results_title character varying(255) DEFAULT NULL::character varying
);


--
-- Name: calculations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calculations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calculations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calculations_id_seq OWNED BY public.calculations.id;


--
-- Name: constraints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.constraints (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    operator character varying(255) NOT NULL,
    lhs double precision,
    rhs double precision NOT NULL,
    decision_id integer NOT NULL,
    option_filter_id integer NOT NULL,
    calculation_id integer,
    variable_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    optional boolean DEFAULT false,
    relaxable boolean DEFAULT false NOT NULL,
    CONSTRAINT calculation_or_variable_required CHECK ((((calculation_id IS NOT NULL) AND (variable_id IS NULL)) OR ((calculation_id IS NULL) AND (variable_id IS NOT NULL))))
);


--
-- Name: constraints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.constraints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: constraints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.constraints_id_seq OWNED BY public.constraints.id;


--
-- Name: criteria_weights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.criteria_weights (
    id integer NOT NULL,
    weighting integer NOT NULL,
    decision_id integer NOT NULL,
    participant_id integer NOT NULL,
    criteria_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: criteria_weights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.criteria_weights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: criteria_weights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.criteria_weights_id_seq OWNED BY public.criteria_weights.id;


--
-- Name: criterias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.criterias (
    id integer NOT NULL,
    title character varying(255),
    slug character varying(255),
    info text,
    bins integer,
    support_only boolean DEFAULT false NOT NULL,
    decision_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    weighting integer,
    deleted boolean DEFAULT false NOT NULL,
    apply_participant_weights boolean DEFAULT true,
    sort integer DEFAULT 0 NOT NULL
);


--
-- Name: criterias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.criterias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: criterias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.criterias_id_seq OWNED BY public.criterias.id;


--
-- Name: decisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.decisions (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    info text,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    copyable boolean DEFAULT false NOT NULL,
    max_users integer DEFAULT 20 NOT NULL,
    language character varying(255) DEFAULT 'en'::character varying NOT NULL,
    published_decision_hash character varying(255) DEFAULT NULL::character varying,
    preview_decision_hash character varying(255) DEFAULT NULL::character varying,
    influent_hash character varying(255) DEFAULT NULL::character varying,
    weighting_hash character varying(255) DEFAULT NULL::character varying,
    internal boolean DEFAULT false NOT NULL,
    keywords jsonb DEFAULT '[]'::jsonb
);


--
-- Name: decisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.decisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: decisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.decisions_id_seq OWNED BY public.decisions.id;



--
-- Name: option_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_categories (
    id integer NOT NULL,
    weighting integer DEFAULT 100 NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    info text,
    decision_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    xor boolean DEFAULT false,
    scoring_mode public.scoring_mode DEFAULT 'none'::public.scoring_mode,
    triangle_base integer DEFAULT 2,
    primary_detail_id integer,
    apply_participant_weights boolean DEFAULT true,
    voting_style public.voting_style DEFAULT 'one'::public.voting_style,
    default_low_option_id integer,
    default_high_option_id integer,
    sort integer DEFAULT 0 NOT NULL,
    budget_percent double precision,
    flat_fee double precision,
    vote_on_percent boolean DEFAULT true NOT NULL,
    results_title character varying(255) DEFAULT NULL::character varying,
    quadratic boolean DEFAULT false NOT NULL,
    keywords text
);


--
-- Name: option_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_categories_id_seq OWNED BY public.option_categories.id;


--
-- Name: option_category_bin_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_category_bin_votes (
    id integer NOT NULL,
    bin integer NOT NULL,
    decision_id integer NOT NULL,
    participant_id integer NOT NULL,
    criteria_id integer NOT NULL,
    option_category_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: option_category_bin_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_category_bin_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_category_bin_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_category_bin_votes_id_seq OWNED BY public.option_category_bin_votes.id;


--
-- Name: option_category_range_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_category_range_votes (
    id integer NOT NULL,
    decision_id integer NOT NULL,
    participant_id integer NOT NULL,
    low_option_id integer NOT NULL,
    high_option_id integer,
    option_category_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: option_category_range_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_category_range_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_category_range_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_category_range_votes_id_seq OWNED BY public.option_category_range_votes.id;


--
-- Name: option_category_weights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_category_weights (
    id integer NOT NULL,
    weighting integer NOT NULL,
    decision_id integer NOT NULL,
    option_category_id integer NOT NULL,
    participant_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: option_category_weights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_category_weights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_category_weights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_category_weights_id_seq OWNED BY public.option_category_weights.id;


--
-- Name: option_detail_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_detail_values (
    value character varying(255),
    option_id integer NOT NULL,
    option_detail_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    decision_id integer
);


--
-- Name: option_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_details (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    public boolean DEFAULT false NOT NULL,
    input_hint character varying(255),
    display_hint character varying(255),
    decision_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    format public.detail_format,
    sort integer DEFAULT 0 NOT NULL
);


--
-- Name: option_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_details_id_seq OWNED BY public.option_details.id;


--
-- Name: option_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_filters (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    match_mode character varying(255) NOT NULL,
    match_value character varying(255) NOT NULL,
    option_detail_id integer,
    decision_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    option_category_id integer,
    CONSTRAINT reference_or_all_match CHECK ((((option_detail_id IS NOT NULL) AND (option_category_id IS NULL) AND ((match_mode)::text <> 'all_options'::text)) OR ((option_detail_id IS NULL) AND (option_category_id IS NOT NULL) AND ((match_mode)::text <> 'all_options'::text)) OR ((option_detail_id IS NULL) AND (option_category_id IS NULL) AND ((match_mode)::text = 'all_options'::text))))
);


--
-- Name: option_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_filters_id_seq OWNED BY public.option_filters.id;


--
-- Name: options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.options (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    info text,
    enabled boolean DEFAULT true NOT NULL,
    decision_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    option_category_id integer,
    deleted boolean DEFAULT false NOT NULL,
    sort integer DEFAULT 0 NOT NULL,
    results_title character varying(255) DEFAULT NULL::character varying,
    determinative boolean DEFAULT false NOT NULL
);


--
-- Name: options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.options_id_seq OWNED BY public.options.id;


--
-- Name: participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.participants (
    id integer NOT NULL,
    weighting numeric(11,5) NOT NULL,
    auxiliary character varying(255),
    decision_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    influent_hash character varying(255) DEFAULT NULL::character varying,
    exclude_optional_constraints boolean DEFAULT false
);


--
-- Name: participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.participants_id_seq OWNED BY public.participants.id;


--
-- Name: scenario_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scenario_configs (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    bins integer NOT NULL,
    support_only boolean DEFAULT false NOT NULL,
    normalize_influents boolean DEFAULT false NOT NULL,
    max_scenarios integer NOT NULL,
    ci numeric(8,7) NOT NULL,
    tipping_point numeric(8,7) NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    decision_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ttl integer DEFAULT 0 NOT NULL,
    skip_solver boolean DEFAULT false NOT NULL,
    override_criteria_weights boolean DEFAULT true NOT NULL,
    override_option_category_weights boolean DEFAULT true NOT NULL,
    per_option_satisfaction boolean DEFAULT false NOT NULL,
    solve_interval integer DEFAULT 0 NOT NULL,
    normalize_satisfaction boolean DEFAULT true NOT NULL,
    preview_engine_hash character varying(255) DEFAULT NULL::character varying,
    published_engine_hash character varying(255) DEFAULT NULL::character varying,
    engine_timeout integer DEFAULT 10000 NOT NULL,
    quadratic boolean DEFAULT false NOT NULL,
    quad_user_seeds integer,
    quad_total_available integer,
    quad_cutoff integer,
    quad_max_allocation integer,
    quad_round_to integer,
    quad_seed_percent double precision,
    quad_vote_percent double precision
);


--
-- Name: scenario_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenario_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scenario_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenario_configs_id_seq OWNED BY public.scenario_configs.id;


--
-- Name: scenario_displays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scenario_displays (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    value double precision NOT NULL,
    is_constraint boolean NOT NULL,
    scenario_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    constraint_id integer,
    calculation_id integer,
    decision_id integer
);


--
-- Name: scenario_displays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenario_displays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scenario_displays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenario_displays_id_seq OWNED BY public.scenario_displays.id;


--
-- Name: scenario_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scenario_sets (
    id integer NOT NULL,
    status character varying(255) NOT NULL,
    decision_id integer NOT NULL,
    scenario_config_id integer,
    participant_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cached_decision boolean DEFAULT false NOT NULL,
    hash character varying(255) DEFAULT NULL::character varying,
    error character varying(255) DEFAULT NULL::character varying,
    breakdown_cache text,
    skip_engine boolean DEFAULT false NOT NULL,
    engine_start timestamp without time zone,
    engine_end timestamp without time zone,
    json_stats text
);


--
-- Name: scenario_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenario_sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scenario_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenario_sets_id_seq OWNED BY public.scenario_sets.id;


--
-- Name: scenario_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scenario_stats (
    id integer NOT NULL,
    histogram integer[],
    total_votes integer,
    negative_votes integer,
    neutral_votes integer,
    positive_votes integer,
    support double precision,
    dissonance double precision,
    ethelo double precision,
    "default" boolean,
    scenario_set_id integer,
    scenario_id integer,
    criteria_id integer,
    option_id integer,
    issue_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    approval double precision,
    average_weight double precision,
    abstain_votes integer,
    advanced_stats integer[],
    decision_id integer,
    seeds_assigned integer,
    positive_seed_votes_sq integer,
    seed_allocation integer,
    vote_allocation integer,
    combined_allocation integer,
    final_allocation integer,
    positive_seed_votes_sum integer
);


--
-- Name: scenario_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenario_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scenario_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenario_stats_id_seq OWNED BY public.scenario_stats.id;


--
-- Name: scenarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scenarios (
    id integer NOT NULL,
    status character varying(255) NOT NULL,
    collective_identity double precision NOT NULL,
    tipping_point double precision NOT NULL,
    minimize boolean NOT NULL,
    global boolean NOT NULL,
    scenario_set_id integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    breakdown_cache text,
    decision_id integer
);


--
-- Name: scenarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scenarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenarios_id_seq OWNED BY public.scenarios.id;


--
-- Name: scenarios_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scenarios_options (
    scenario_id integer,
    option_id integer
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: solve_dumps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solve_dumps (
    id integer NOT NULL,
    decision_id integer NOT NULL,
    participant_id integer,
    scenario_set_id integer NOT NULL,
    decision_json text,
    influents_json text,
    weights_json text,
    config_json text,
    response_json text,
    error text,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: solve_dumps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solve_dumps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solve_dumps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solve_dumps_id_seq OWNED BY public.solve_dumps.id;


--
-- Name: variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.variables (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    method public.variable_method NOT NULL,
    decision_id integer NOT NULL,
    option_detail_id integer,
    option_filter_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    CONSTRAINT detail_or_filter_required CHECK ((((option_detail_id IS NOT NULL) AND (option_filter_id IS NULL)) OR ((option_detail_id IS NULL) AND (option_filter_id IS NOT NULL))))
);


--
-- Name: variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.variables_id_seq OWNED BY public.variables.id;


--
-- Name: bin_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes ALTER COLUMN id SET DEFAULT nextval('public.bin_votes_id_seq'::regclass);


--
-- Name: cache id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache ALTER COLUMN id SET DEFAULT nextval('public.cache_id_seq'::regclass);


--
-- Name: calculations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculations ALTER COLUMN id SET DEFAULT nextval('public.calculations_id_seq'::regclass);


--
-- Name: constraints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints ALTER COLUMN id SET DEFAULT nextval('public.constraints_id_seq'::regclass);


--
-- Name: criteria_weights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights ALTER COLUMN id SET DEFAULT nextval('public.criteria_weights_id_seq'::regclass);


--
-- Name: criterias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterias ALTER COLUMN id SET DEFAULT nextval('public.criterias_id_seq'::regclass);


--
-- Name: decisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decisions ALTER COLUMN id SET DEFAULT nextval('public.decisions_id_seq'::regclass);

--
-- Name: option_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories ALTER COLUMN id SET DEFAULT nextval('public.option_categories_id_seq'::regclass);


--
-- Name: option_category_bin_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes ALTER COLUMN id SET DEFAULT nextval('public.option_category_bin_votes_id_seq'::regclass);


--
-- Name: option_category_range_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes ALTER COLUMN id SET DEFAULT nextval('public.option_category_range_votes_id_seq'::regclass);


--
-- Name: option_category_weights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights ALTER COLUMN id SET DEFAULT nextval('public.option_category_weights_id_seq'::regclass);


--
-- Name: option_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_details ALTER COLUMN id SET DEFAULT nextval('public.option_details_id_seq'::regclass);


--
-- Name: option_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters ALTER COLUMN id SET DEFAULT nextval('public.option_filters_id_seq'::regclass);


--
-- Name: options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options ALTER COLUMN id SET DEFAULT nextval('public.options_id_seq'::regclass);


--
-- Name: participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants ALTER COLUMN id SET DEFAULT nextval('public.participants_id_seq'::regclass);


--
-- Name: scenario_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_configs ALTER COLUMN id SET DEFAULT nextval('public.scenario_configs_id_seq'::regclass);


--
-- Name: scenario_displays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays ALTER COLUMN id SET DEFAULT nextval('public.scenario_displays_id_seq'::regclass);


--
-- Name: scenario_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets ALTER COLUMN id SET DEFAULT nextval('public.scenario_sets_id_seq'::regclass);


--
-- Name: scenario_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_stats ALTER COLUMN id SET DEFAULT nextval('public.scenario_stats_id_seq'::regclass);


--
-- Name: scenarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios ALTER COLUMN id SET DEFAULT nextval('public.scenarios_id_seq'::regclass);


--
-- Name: solve_dumps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps ALTER COLUMN id SET DEFAULT nextval('public.solve_dumps_id_seq'::regclass);


--
-- Name: variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables ALTER COLUMN id SET DEFAULT nextval('public.variables_id_seq'::regclass);


--
-- Name: bin_votes bin_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_pkey PRIMARY KEY (id);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (id);


--
-- Name: calculation_variables calculation_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculation_variables
    ADD CONSTRAINT calculation_variables_pkey PRIMARY KEY (calculation_id, variable_id);


--
-- Name: calculations calculations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculations
    ADD CONSTRAINT calculations_pkey PRIMARY KEY (id);


--
-- Name: constraints constraints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_pkey PRIMARY KEY (id);


--
-- Name: criteria_weights criteria_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights
    ADD CONSTRAINT criteria_weights_pkey PRIMARY KEY (id);


--
-- Name: criterias criterias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterias
    ADD CONSTRAINT criterias_pkey PRIMARY KEY (id);


--
-- Name: decisions decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decisions
    ADD CONSTRAINT decisions_pkey PRIMARY KEY (id);


--
-- Name: option_categories option_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_pkey PRIMARY KEY (id);


--
-- Name: option_category_bin_votes option_category_bin_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_pkey PRIMARY KEY (id);


--
-- Name: option_category_range_votes option_category_range_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_pkey PRIMARY KEY (id);


--
-- Name: option_category_weights option_category_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights
    ADD CONSTRAINT option_category_weights_pkey PRIMARY KEY (id);


--
-- Name: option_detail_values option_detail_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_detail_values
    ADD CONSTRAINT option_detail_values_pkey PRIMARY KEY (option_id, option_detail_id);


--
-- Name: option_details option_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_details
    ADD CONSTRAINT option_details_pkey PRIMARY KEY (id);


--
-- Name: option_filters option_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters
    ADD CONSTRAINT option_filters_pkey PRIMARY KEY (id);


--
-- Name: options options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT options_pkey PRIMARY KEY (id);


--
-- Name: participants participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_pkey PRIMARY KEY (id);


--
-- Name: scenario_configs scenario_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_configs
    ADD CONSTRAINT scenario_configs_pkey PRIMARY KEY (id);


--
-- Name: scenario_displays scenario_displays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_pkey PRIMARY KEY (id);


--
-- Name: scenario_sets scenario_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets
    ADD CONSTRAINT scenario_sets_pkey PRIMARY KEY (id);


--
-- Name: scenario_stats scenario_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_stats
    ADD CONSTRAINT scenario_stats_pkey PRIMARY KEY (id);


--
-- Name: scenarios scenarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: solve_dumps solve_dumps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps
    ADD CONSTRAINT solve_dumps_pkey PRIMARY KEY (id);


--
-- Name: variables variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_pkey PRIMARY KEY (id);


--
-- Name: bin_votes_criteria_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_criteria_id_index ON public.bin_votes USING btree (criteria_id);


--
-- Name: bin_votes_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_decision_id_index ON public.bin_votes USING btree (decision_id);


--
-- Name: bin_votes_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_option_id_index ON public.bin_votes USING btree (option_id);


--
-- Name: bin_votes_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_participant_id_index ON public.bin_votes USING btree (participant_id);


--
-- Name: bin_votes_updated_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_updated_at_index ON public.bin_votes USING btree (updated_at);


--
-- Name: cache_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cache_decision_id_index ON public.cache USING btree (decision_id);


--
-- Name: cache_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cache_key_index ON public.cache USING btree (key);


--
-- Name: calculations_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX calculations_decision_id_index ON public.calculations USING btree (decision_id);


--
-- Name: constraints_calculation_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX constraints_calculation_id_index ON public.constraints USING btree (calculation_id);


--
-- Name: constraints_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX constraints_decision_id_index ON public.constraints USING btree (decision_id);


--
-- Name: constraints_option_filter_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX constraints_option_filter_id_index ON public.constraints USING btree (option_filter_id);


--
-- Name: constraints_variable_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX constraints_variable_id_index ON public.constraints USING btree (variable_id);


--
-- Name: criteria_weights_criteria_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criteria_weights_criteria_id_index ON public.criteria_weights USING btree (criteria_id);


--
-- Name: criteria_weights_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criteria_weights_decision_id_index ON public.criteria_weights USING btree (decision_id);


--
-- Name: criteria_weights_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criteria_weights_participant_id_index ON public.criteria_weights USING btree (participant_id);


--
-- Name: criteria_weights_updated_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criteria_weights_updated_at_index ON public.criteria_weights USING btree (updated_at);


--
-- Name: criterias_decision_id_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criterias_decision_id_id_index ON public.criterias USING btree (decision_id, id);


--
-- Name: criterias_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criterias_decision_id_index ON public.criterias USING btree (decision_id);


--
-- Name: decision_keywords; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX decision_keywords ON public.decisions USING gin (keywords);


--
-- Name: decisions_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX decisions_slug_index ON public.decisions USING btree (slug);


--
-- Name: option_categories_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_categories_decision_id_index ON public.option_categories USING btree (decision_id);


--
-- Name: option_category_bin_votes_criteria_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_bin_votes_criteria_id_index ON public.option_category_bin_votes USING btree (criteria_id);


--
-- Name: option_category_bin_votes_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_bin_votes_decision_id_index ON public.option_category_bin_votes USING btree (decision_id);


--
-- Name: option_category_bin_votes_option_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_bin_votes_option_category_id_index ON public.option_category_bin_votes USING btree (option_category_id);


--
-- Name: option_category_bin_votes_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_bin_votes_participant_id_index ON public.option_category_bin_votes USING btree (participant_id);


--
-- Name: option_category_range_votes_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_decision_id_index ON public.option_category_range_votes USING btree (decision_id);


--
-- Name: option_category_range_votes_high_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_high_option_id_index ON public.option_category_range_votes USING btree (high_option_id);


--
-- Name: option_category_range_votes_low_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_low_option_id_index ON public.option_category_range_votes USING btree (low_option_id);


--
-- Name: option_category_range_votes_option_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_option_category_id_index ON public.option_category_range_votes USING btree (option_category_id);


--
-- Name: option_category_range_votes_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_participant_id_index ON public.option_category_range_votes USING btree (participant_id);


--
-- Name: option_category_range_votes_updated_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_updated_at_index ON public.option_category_range_votes USING btree (updated_at);


--
-- Name: option_category_weights_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_weights_decision_id_index ON public.option_category_weights USING btree (decision_id);


--
-- Name: option_category_weights_option_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_weights_option_category_id_index ON public.option_category_weights USING btree (option_category_id);


--
-- Name: option_category_weights_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_weights_participant_id_index ON public.option_category_weights USING btree (participant_id);


--
-- Name: option_category_weights_updated_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_weights_updated_at_index ON public.option_category_weights USING btree (updated_at);


--
-- Name: option_detail_values_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_detail_values_decision_id_index ON public.option_detail_values USING btree (decision_id);


--
-- Name: option_details_decision_id_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_details_decision_id_id_index ON public.option_details USING btree (decision_id, id);


--
-- Name: option_details_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_details_decision_id_index ON public.option_details USING btree (decision_id);


--
-- Name: option_filters_decision_id_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_filters_decision_id_id_index ON public.option_filters USING btree (decision_id, id);


--
-- Name: option_filters_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_filters_decision_id_index ON public.option_filters USING btree (decision_id);


--
-- Name: options_decision_id_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX options_decision_id_id_index ON public.options USING btree (decision_id, id);


--
-- Name: options_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX options_decision_id_index ON public.options USING btree (decision_id);


--
-- Name: options_option_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX options_option_category_id_index ON public.options USING btree (option_category_id);


--
-- Name: participants_auxiliary_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX participants_auxiliary_index ON public.participants USING btree (auxiliary);


--
-- Name: participants_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX participants_decision_id_index ON public.participants USING btree (decision_id);


--
-- Name: scenario_configs_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_configs_decision_id_index ON public.scenario_configs USING btree (decision_id);


--
-- Name: scenario_displays_calculation_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_calculation_id_index ON public.scenario_displays USING btree (calculation_id);


--
-- Name: scenario_displays_constraint_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_constraint_id_index ON public.scenario_displays USING btree (constraint_id);


--
-- Name: scenario_displays_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_decision_id_index ON public.scenario_displays USING btree (decision_id);


--
-- Name: scenario_displays_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_name_index ON public.scenario_displays USING btree (name);


--
-- Name: scenario_displays_scenario_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_scenario_id_index ON public.scenario_displays USING btree (scenario_id);


--
-- Name: scenario_sets_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_decision_id_index ON public.scenario_sets USING btree (decision_id);


--
-- Name: scenario_sets_decision_id_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_decision_id_status_index ON public.scenario_sets USING btree (decision_id, status);


--
-- Name: scenario_sets_hash_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_hash_index ON public.scenario_sets USING btree (hash);


--
-- Name: scenario_sets_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_participant_id_index ON public.scenario_sets USING btree (participant_id);


--
-- Name: scenario_sets_scenario_config_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_scenario_config_id_index ON public.scenario_sets USING btree (scenario_config_id);


--
-- Name: scenario_stats_criteria_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_stats_criteria_id_index ON public.scenario_stats USING btree (criteria_id);


--
-- Name: scenario_stats_decision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_stats_decision_id ON public.scenario_stats USING btree (decision_id);


--
-- Name: scenario_stats_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_stats_decision_id_index ON public.scenario_stats USING btree (decision_id);


--
-- Name: scenario_stats_default_unique_criteria; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scenario_stats_default_unique_criteria ON public.scenario_stats USING btree (scenario_set_id, "default", option_id, criteria_id) WHERE ("default" = true);


--
-- Name: scenario_stats_default_unique_issues; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scenario_stats_default_unique_issues ON public.scenario_stats USING btree (scenario_set_id, "default", issue_id) WHERE ("default" = true);


--
-- Name: scenario_stats_default_unique_options; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scenario_stats_default_unique_options ON public.scenario_stats USING btree (scenario_set_id, "default", option_id) WHERE (("default" = true) AND (criteria_id IS NULL));


--
-- Name: scenario_stats_issue_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_stats_issue_id_index ON public.scenario_stats USING btree (issue_id);


--
-- Name: scenario_stats_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_stats_option_id_index ON public.scenario_stats USING btree (option_id);


--
-- Name: scenario_stats_scenario_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_stats_scenario_id_index ON public.scenario_stats USING btree (scenario_id);


--
-- Name: scenario_stats_solution_unique_criteria; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scenario_stats_solution_unique_criteria ON public.scenario_stats USING btree (scenario_id, "default", option_id, criteria_id) WHERE ("default" = false);


--
-- Name: scenario_stats_solution_unique_issues; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scenario_stats_solution_unique_issues ON public.scenario_stats USING btree (scenario_id, "default", issue_id) WHERE ("default" = false);


--
-- Name: scenario_stats_solution_unique_options; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scenario_stats_solution_unique_options ON public.scenario_stats USING btree (scenario_id, "default", option_id) WHERE (("default" = false) AND (criteria_id IS NULL));


--
-- Name: scenarios_decision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_decision_id ON public.scenarios USING btree (decision_id);


--
-- Name: scenarios_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_decision_id_index ON public.scenarios USING btree (decision_id);


--
-- Name: scenarios_global_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_global_index ON public.scenarios USING btree (global);


--
-- Name: scenarios_minimize_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_minimize_index ON public.scenarios USING btree (minimize);


--
-- Name: scenarios_scenario_set_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_scenario_set_id_index ON public.scenarios USING btree (scenario_set_id);


--
-- Name: scenarios_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_status_index ON public.scenarios USING btree (status);


--
-- Name: solve_dumps_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX solve_dumps_decision_id_index ON public.solve_dumps USING btree (decision_id);


--
-- Name: solve_dumps_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX solve_dumps_participant_id_index ON public.solve_dumps USING btree (participant_id);


--
-- Name: solve_dumps_scenario_set_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX solve_dumps_scenario_set_id_index ON public.solve_dumps USING btree (scenario_set_id);


--
-- Name: unique_all_options; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_all_options ON public.option_filters USING btree (decision_id, match_mode) WHERE ((match_mode)::text = 'all_options'::text);


--
-- Name: unique_cache_decision_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_cache_decision_key ON public.cache USING btree (decision_id, key);


--
-- Name: unique_calculation_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_calculation_slug_index ON public.calculations USING btree (decision_id, slug);


--
-- Name: unique_constraint_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_constraint_slug_index ON public.constraints USING btree (decision_id, slug);


--
-- Name: unique_criteria_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_criteria_slug_index ON public.criterias USING btree (decision_id, slug);


--
-- Name: unique_detail_variable_config_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_detail_variable_config_index ON public.variables USING btree (option_detail_id, method);


--
-- Name: unique_filter_variable_config_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_filter_variable_config_index ON public.variables USING btree (option_filter_id, method);


--
-- Name: unique_option_category_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_category_slug_index ON public.option_categories USING btree (decision_id, slug);


--
-- Name: unique_option_detail_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_detail_slug_index ON public.option_details USING btree (decision_id, slug);


--
-- Name: unique_option_filter_category_config_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_filter_category_config_index ON public.option_filters USING btree (option_category_id, match_mode);


--
-- Name: unique_option_filter_detail_config_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_filter_detail_config_index ON public.option_filters USING btree (option_detail_id, match_mode, match_value);


--
-- Name: unique_option_filter_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_filter_slug_index ON public.option_filters USING btree (decision_id, slug);


--
-- Name: unique_option_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_slug_index ON public.options USING btree (decision_id, slug);


--
-- Name: unique_p_oc_bin_vote_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_p_oc_bin_vote_index ON public.option_category_bin_votes USING btree (criteria_id, participant_id, option_category_id);


--
-- Name: unique_p_oc_range_vote; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_p_oc_range_vote ON public.option_category_range_votes USING btree (participant_id, option_category_id);


--
-- Name: unique_participant_bin_vote_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_participant_bin_vote_index ON public.bin_votes USING btree (criteria_id, participant_id, option_id);


--
-- Name: unique_participant_criteria_weight_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_participant_criteria_weight_index ON public.criteria_weights USING btree (criteria_id, participant_id);


--
-- Name: unique_participant_filter_weight_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_participant_filter_weight_index ON public.option_category_weights USING btree (option_category_id, participant_id);


--
-- Name: unique_scenario_config_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_scenario_config_slug_index ON public.scenario_configs USING btree (decision_id, slug);


--
-- Name: unique_variable_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_variable_slug_index ON public.variables USING btree (decision_id, slug);


--
-- Name: variables_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX variables_decision_id_index ON public.variables USING btree (decision_id);


--
-- Name: variables_option_detail_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX variables_option_detail_id_index ON public.variables USING btree (option_detail_id);


--
-- Name: variables_option_filter_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX variables_option_filter_id_index ON public.variables USING btree (option_filter_id);


--
-- Name: bin_votes bin_votes_criteria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_criteria_id_fkey FOREIGN KEY (criteria_id) REFERENCES public.criterias(id) ON DELETE CASCADE;


--
-- Name: bin_votes bin_votes_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: bin_votes bin_votes_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- Name: bin_votes bin_votes_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- Name: cache cache_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: calculation_variables calculation_variables_calculation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculation_variables
    ADD CONSTRAINT calculation_variables_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES public.calculations(id) ON DELETE CASCADE;


--
-- Name: calculation_variables calculation_variables_variable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculation_variables
    ADD CONSTRAINT calculation_variables_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.variables(id) ON DELETE CASCADE;


--
-- Name: calculations calculations_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculations
    ADD CONSTRAINT calculations_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: constraints constraints_calculation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES public.calculations(id) ON DELETE CASCADE;


--
-- Name: constraints constraints_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: constraints constraints_option_filter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_option_filter_id_fkey FOREIGN KEY (option_filter_id) REFERENCES public.option_filters(id) ON DELETE CASCADE;


--
-- Name: constraints constraints_variable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.variables(id) ON DELETE CASCADE;


--
-- Name: criteria_weights criteria_weights_criteria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights
    ADD CONSTRAINT criteria_weights_criteria_id_fkey FOREIGN KEY (criteria_id) REFERENCES public.criterias(id) ON DELETE CASCADE;


--
-- Name: criteria_weights criteria_weights_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights
    ADD CONSTRAINT criteria_weights_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: criteria_weights criteria_weights_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights
    ADD CONSTRAINT criteria_weights_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- Name: criterias criterias_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterias
    ADD CONSTRAINT criterias_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: option_categories option_categories_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: option_categories option_categories_default_high_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_default_high_option_id_fkey FOREIGN KEY (default_high_option_id) REFERENCES public.options(id) ON DELETE SET NULL;


--
-- Name: option_categories option_categories_default_low_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_default_low_option_id_fkey FOREIGN KEY (default_low_option_id) REFERENCES public.options(id) ON DELETE SET NULL;


--
-- Name: option_categories option_categories_primary_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_primary_detail_id_fkey FOREIGN KEY (primary_detail_id) REFERENCES public.option_details(id) ON DELETE SET NULL;


--
-- Name: option_category_bin_votes option_category_bin_votes_criteria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_criteria_id_fkey FOREIGN KEY (criteria_id) REFERENCES public.criterias(id) ON DELETE CASCADE;


--
-- Name: option_category_bin_votes option_category_bin_votes_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: option_category_bin_votes option_category_bin_votes_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- Name: option_category_bin_votes option_category_bin_votes_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- Name: option_category_range_votes option_category_range_votes_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: option_category_range_votes option_category_range_votes_high_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_high_option_id_fkey FOREIGN KEY (high_option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- Name: option_category_range_votes option_category_range_votes_low_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_low_option_id_fkey FOREIGN KEY (low_option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- Name: option_category_range_votes option_category_range_votes_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- Name: option_category_range_votes option_category_range_votes_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- Name: option_category_weights option_category_weights_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights
    ADD CONSTRAINT option_category_weights_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: option_category_weights option_category_weights_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights
    ADD CONSTRAINT option_category_weights_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- Name: option_category_weights option_category_weights_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights
    ADD CONSTRAINT option_category_weights_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- Name: option_detail_values option_detail_values_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_detail_values
    ADD CONSTRAINT option_detail_values_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: option_detail_values option_detail_values_option_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_detail_values
    ADD CONSTRAINT option_detail_values_option_detail_id_fkey FOREIGN KEY (option_detail_id) REFERENCES public.option_details(id) ON DELETE CASCADE;


--
-- Name: option_detail_values option_detail_values_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_detail_values
    ADD CONSTRAINT option_detail_values_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- Name: option_details option_details_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_details
    ADD CONSTRAINT option_details_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: option_filters option_filters_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters
    ADD CONSTRAINT option_filters_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: option_filters option_filters_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters
    ADD CONSTRAINT option_filters_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- Name: option_filters option_filters_option_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters
    ADD CONSTRAINT option_filters_option_detail_id_fkey FOREIGN KEY (option_detail_id) REFERENCES public.option_details(id) ON DELETE CASCADE;


--
-- Name: options options_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT options_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: options options_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT options_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE SET NULL;


--
-- Name: participants participants_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: scenario_configs scenario_configs_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_configs
    ADD CONSTRAINT scenario_configs_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: scenario_displays scenario_displays_calculation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES public.calculations(id) ON DELETE CASCADE;


--
-- Name: scenario_displays scenario_displays_constraint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_constraint_id_fkey FOREIGN KEY (constraint_id) REFERENCES public.constraints(id) ON DELETE CASCADE;


--
-- Name: scenario_displays scenario_displays_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: scenario_displays scenario_displays_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.scenarios(id) ON DELETE CASCADE;


--
-- Name: scenario_sets scenario_sets_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets
    ADD CONSTRAINT scenario_sets_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: scenario_sets scenario_sets_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets
    ADD CONSTRAINT scenario_sets_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- Name: scenario_sets scenario_sets_scenario_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets
    ADD CONSTRAINT scenario_sets_scenario_config_id_fkey FOREIGN KEY (scenario_config_id) REFERENCES public.scenario_configs(id) ON DELETE CASCADE;


--
-- Name: scenario_stats scenario_stats_criteria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_stats
    ADD CONSTRAINT scenario_stats_criteria_id_fkey FOREIGN KEY (criteria_id) REFERENCES public.criterias(id) ON DELETE CASCADE;


--
-- Name: scenario_stats scenario_stats_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_stats
    ADD CONSTRAINT scenario_stats_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: scenario_stats scenario_stats_issue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_stats
    ADD CONSTRAINT scenario_stats_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- Name: scenario_stats scenario_stats_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_stats
    ADD CONSTRAINT scenario_stats_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- Name: scenario_stats scenario_stats_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_stats
    ADD CONSTRAINT scenario_stats_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.scenarios(id) ON DELETE CASCADE;


--
-- Name: scenario_stats scenario_stats_scenario_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_stats
    ADD CONSTRAINT scenario_stats_scenario_set_id_fkey FOREIGN KEY (scenario_set_id) REFERENCES public.scenario_sets(id) ON DELETE CASCADE;


--
-- Name: scenarios scenarios_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: scenarios_options scenarios_options_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios_options
    ADD CONSTRAINT scenarios_options_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- Name: scenarios_options scenarios_options_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios_options
    ADD CONSTRAINT scenarios_options_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.scenarios(id) ON DELETE CASCADE;


--
-- Name: scenarios scenarios_scenario_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_scenario_set_id_fkey FOREIGN KEY (scenario_set_id) REFERENCES public.scenario_sets(id) ON DELETE CASCADE;


--
-- Name: solve_dumps solve_dumps_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps
    ADD CONSTRAINT solve_dumps_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: solve_dumps solve_dumps_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps
    ADD CONSTRAINT solve_dumps_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- Name: solve_dumps solve_dumps_scenario_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps
    ADD CONSTRAINT solve_dumps_scenario_set_id_fkey FOREIGN KEY (scenario_set_id) REFERENCES public.scenario_sets(id) ON DELETE CASCADE;


--
-- Name: variables variables_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- Name: variables variables_option_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_option_detail_id_fkey FOREIGN KEY (option_detail_id) REFERENCES public.option_details(id) ON DELETE CASCADE;


--
-- Name: variables variables_option_filter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_option_filter_id_fkey FOREIGN KEY (option_filter_id) REFERENCES public.option_filters(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20240621173603);
