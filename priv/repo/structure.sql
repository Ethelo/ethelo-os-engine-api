--
-- PostgreSQL database dump
--

-- Dumped from database version 11.22
-- Dumped by pg_dump version 16.3

-- Started on 2024-08-01 14:51:26 PDT

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

DROP DATABASE IF EXISTS ethelo_prod;
--
-- TOC entry 3925 (class 1262 OID 71952)
-- Name: ethelo_prod; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE ethelo_prod WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


\connect ethelo_prod

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

SET default_tablespace = '';

--
-- TOC entry 196 (class 1259 OID 72003)
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
-- TOC entry 197 (class 1259 OID 72006)
-- Name: bin_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bin_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3926 (class 0 OID 0)
-- Dependencies: 197
-- Name: bin_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bin_votes_id_seq OWNED BY public.bin_votes.id;


--
-- TOC entry 198 (class 1259 OID 72008)
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
-- TOC entry 199 (class 1259 OID 72014)
-- Name: cache_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cache_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3927 (class 0 OID 0)
-- Dependencies: 199
-- Name: cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cache_id_seq OWNED BY public.cache.id;


--
-- TOC entry 200 (class 1259 OID 72016)
-- Name: calculation_variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calculation_variables (
    calculation_id integer NOT NULL,
    variable_id integer NOT NULL
);


--
-- TOC entry 201 (class 1259 OID 72019)
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
-- TOC entry 202 (class 1259 OID 72028)
-- Name: calculations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calculations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3928 (class 0 OID 0)
-- Dependencies: 202
-- Name: calculations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calculations_id_seq OWNED BY public.calculations.id;


--
-- TOC entry 203 (class 1259 OID 72030)
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
    relaxable boolean DEFAULT false NOT NULL,
    CONSTRAINT calculation_or_variable_required CHECK ((((calculation_id IS NOT NULL) AND (variable_id IS NULL)) OR ((calculation_id IS NULL) AND (variable_id IS NOT NULL))))
);


--
-- TOC entry 204 (class 1259 OID 72038)
-- Name: constraints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.constraints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3929 (class 0 OID 0)
-- Dependencies: 204
-- Name: constraints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.constraints_id_seq OWNED BY public.constraints.id;


--
-- TOC entry 205 (class 1259 OID 72040)
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
-- TOC entry 206 (class 1259 OID 72043)
-- Name: criteria_weights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.criteria_weights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3930 (class 0 OID 0)
-- Dependencies: 206
-- Name: criteria_weights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.criteria_weights_id_seq OWNED BY public.criteria_weights.id;


--
-- TOC entry 207 (class 1259 OID 72045)
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
-- TOC entry 208 (class 1259 OID 72055)
-- Name: criterias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.criterias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3931 (class 0 OID 0)
-- Dependencies: 208
-- Name: criterias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.criterias_id_seq OWNED BY public.criterias.id;


--
-- TOC entry 209 (class 1259 OID 72057)
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
-- TOC entry 210 (class 1259 OID 72070)
-- Name: decisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.decisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3932 (class 0 OID 0)
-- Dependencies: 210
-- Name: decisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.decisions_id_seq OWNED BY public.decisions.id;


--
-- TOC entry 211 (class 1259 OID 72072)
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
-- TOC entry 212 (class 1259 OID 72086)
-- Name: option_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3933 (class 0 OID 0)
-- Dependencies: 212
-- Name: option_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_categories_id_seq OWNED BY public.option_categories.id;


--
-- TOC entry 213 (class 1259 OID 72088)
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
-- TOC entry 214 (class 1259 OID 72091)
-- Name: option_category_bin_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_category_bin_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3934 (class 0 OID 0)
-- Dependencies: 214
-- Name: option_category_bin_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_category_bin_votes_id_seq OWNED BY public.option_category_bin_votes.id;


--
-- TOC entry 215 (class 1259 OID 72093)
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
-- TOC entry 216 (class 1259 OID 72096)
-- Name: option_category_range_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_category_range_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3935 (class 0 OID 0)
-- Dependencies: 216
-- Name: option_category_range_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_category_range_votes_id_seq OWNED BY public.option_category_range_votes.id;


--
-- TOC entry 217 (class 1259 OID 72098)
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
-- TOC entry 218 (class 1259 OID 72101)
-- Name: option_category_weights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_category_weights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3936 (class 0 OID 0)
-- Dependencies: 218
-- Name: option_category_weights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_category_weights_id_seq OWNED BY public.option_category_weights.id;


--
-- TOC entry 219 (class 1259 OID 72103)
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
-- TOC entry 220 (class 1259 OID 72106)
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
-- TOC entry 221 (class 1259 OID 72114)
-- Name: option_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3937 (class 0 OID 0)
-- Dependencies: 221
-- Name: option_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_details_id_seq OWNED BY public.option_details.id;


--
-- TOC entry 222 (class 1259 OID 72116)
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
-- TOC entry 223 (class 1259 OID 72123)
-- Name: option_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3938 (class 0 OID 0)
-- Dependencies: 223
-- Name: option_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_filters_id_seq OWNED BY public.option_filters.id;


--
-- TOC entry 224 (class 1259 OID 72125)
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
-- TOC entry 225 (class 1259 OID 72134)
-- Name: options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3939 (class 0 OID 0)
-- Dependencies: 225
-- Name: options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.options_id_seq OWNED BY public.options.id;


--
-- TOC entry 226 (class 1259 OID 72136)
-- Name: participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.participants (
    id integer NOT NULL,
    weighting numeric(10,5) NOT NULL,
    auxiliary character varying(255),
    decision_id integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    influent_hash character varying(255) DEFAULT NULL::character varying
);


--
-- TOC entry 227 (class 1259 OID 72143)
-- Name: participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3940 (class 0 OID 0)
-- Dependencies: 227
-- Name: participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.participants_id_seq OWNED BY public.participants.id;


--
-- TOC entry 228 (class 1259 OID 72145)
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
-- TOC entry 229 (class 1259 OID 72164)
-- Name: scenario_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenario_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3941 (class 0 OID 0)
-- Dependencies: 229
-- Name: scenario_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenario_configs_id_seq OWNED BY public.scenario_configs.id;


--
-- TOC entry 230 (class 1259 OID 72166)
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
-- TOC entry 231 (class 1259 OID 72169)
-- Name: scenario_displays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenario_displays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3942 (class 0 OID 0)
-- Dependencies: 231
-- Name: scenario_displays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenario_displays_id_seq OWNED BY public.scenario_displays.id;


--
-- TOC entry 232 (class 1259 OID 72171)
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
    engine_start timestamp without time zone,
    engine_end timestamp without time zone,
    json_stats text
);


--
-- TOC entry 233 (class 1259 OID 72180)
-- Name: scenario_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenario_sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3943 (class 0 OID 0)
-- Dependencies: 233
-- Name: scenario_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenario_sets_id_seq OWNED BY public.scenario_sets.id;


--
-- TOC entry 236 (class 1259 OID 72190)
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
    decision_id integer
);


--
-- TOC entry 237 (class 1259 OID 72193)
-- Name: scenarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scenarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3944 (class 0 OID 0)
-- Dependencies: 237
-- Name: scenarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scenarios_id_seq OWNED BY public.scenarios.id;


--
-- TOC entry 238 (class 1259 OID 72195)
-- Name: scenarios_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scenarios_options (
    scenario_id integer,
    option_id integer
);


--
-- TOC entry 239 (class 1259 OID 72198)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- TOC entry 243 (class 1259 OID 79516)
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
-- TOC entry 242 (class 1259 OID 79514)
-- Name: solve_dumps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solve_dumps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3945 (class 0 OID 0)
-- Dependencies: 242
-- Name: solve_dumps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solve_dumps_id_seq OWNED BY public.solve_dumps.id;


--
-- TOC entry 240 (class 1259 OID 72201)
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
-- TOC entry 241 (class 1259 OID 72208)
-- Name: variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3946 (class 0 OID 0)
-- Dependencies: 241
-- Name: variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.variables_id_seq OWNED BY public.variables.id;


--
-- TOC entry 3525 (class 2604 OID 72210)
-- Name: bin_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes ALTER COLUMN id SET DEFAULT nextval('public.bin_votes_id_seq'::regclass);


--
-- TOC entry 3526 (class 2604 OID 72211)
-- Name: cache id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache ALTER COLUMN id SET DEFAULT nextval('public.cache_id_seq'::regclass);


--
-- TOC entry 3527 (class 2604 OID 72212)
-- Name: calculations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculations ALTER COLUMN id SET DEFAULT nextval('public.calculations_id_seq'::regclass);


--
-- TOC entry 3531 (class 2604 OID 72213)
-- Name: constraints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints ALTER COLUMN id SET DEFAULT nextval('public.constraints_id_seq'::regclass);


--
-- TOC entry 3534 (class 2604 OID 72214)
-- Name: criteria_weights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights ALTER COLUMN id SET DEFAULT nextval('public.criteria_weights_id_seq'::regclass);


--
-- TOC entry 3535 (class 2604 OID 72215)
-- Name: criterias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterias ALTER COLUMN id SET DEFAULT nextval('public.criterias_id_seq'::regclass);


--
-- TOC entry 3540 (class 2604 OID 72216)
-- Name: decisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decisions ALTER COLUMN id SET DEFAULT nextval('public.decisions_id_seq'::regclass);


--
-- TOC entry 3550 (class 2604 OID 72217)
-- Name: option_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories ALTER COLUMN id SET DEFAULT nextval('public.option_categories_id_seq'::regclass);


--
-- TOC entry 3562 (class 2604 OID 72218)
-- Name: option_category_bin_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes ALTER COLUMN id SET DEFAULT nextval('public.option_category_bin_votes_id_seq'::regclass);


--
-- TOC entry 3563 (class 2604 OID 72219)
-- Name: option_category_range_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes ALTER COLUMN id SET DEFAULT nextval('public.option_category_range_votes_id_seq'::regclass);


--
-- TOC entry 3564 (class 2604 OID 72220)
-- Name: option_category_weights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights ALTER COLUMN id SET DEFAULT nextval('public.option_category_weights_id_seq'::regclass);


--
-- TOC entry 3565 (class 2604 OID 72221)
-- Name: option_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_details ALTER COLUMN id SET DEFAULT nextval('public.option_details_id_seq'::regclass);


--
-- TOC entry 3568 (class 2604 OID 72222)
-- Name: option_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters ALTER COLUMN id SET DEFAULT nextval('public.option_filters_id_seq'::regclass);


--
-- TOC entry 3569 (class 2604 OID 72223)
-- Name: options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options ALTER COLUMN id SET DEFAULT nextval('public.options_id_seq'::regclass);


--
-- TOC entry 3575 (class 2604 OID 72224)
-- Name: participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants ALTER COLUMN id SET DEFAULT nextval('public.participants_id_seq'::regclass);


--
-- TOC entry 3577 (class 2604 OID 72225)
-- Name: scenario_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_configs ALTER COLUMN id SET DEFAULT nextval('public.scenario_configs_id_seq'::regclass);


--
-- TOC entry 3592 (class 2604 OID 72226)
-- Name: scenario_displays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays ALTER COLUMN id SET DEFAULT nextval('public.scenario_displays_id_seq'::regclass);


--
-- TOC entry 3593 (class 2604 OID 72227)
-- Name: scenario_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets ALTER COLUMN id SET DEFAULT nextval('public.scenario_sets_id_seq'::regclass);


--
-- TOC entry 3597 (class 2604 OID 72229)
-- Name: scenarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios ALTER COLUMN id SET DEFAULT nextval('public.scenarios_id_seq'::regclass);


--
-- TOC entry 3599 (class 2604 OID 79519)
-- Name: solve_dumps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps ALTER COLUMN id SET DEFAULT nextval('public.solve_dumps_id_seq'::regclass);


--
-- TOC entry 3598 (class 2604 OID 72230)
-- Name: variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables ALTER COLUMN id SET DEFAULT nextval('public.variables_id_seq'::regclass);


--
-- TOC entry 3608 (class 2606 OID 72295)
-- Name: bin_votes bin_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_pkey PRIMARY KEY (id);


--
-- TOC entry 3614 (class 2606 OID 72297)
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (id);


--
-- TOC entry 3617 (class 2606 OID 72299)
-- Name: calculation_variables calculation_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculation_variables
    ADD CONSTRAINT calculation_variables_pkey PRIMARY KEY (calculation_id, variable_id);


--
-- TOC entry 3620 (class 2606 OID 72301)
-- Name: calculations calculations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculations
    ADD CONSTRAINT calculations_pkey PRIMARY KEY (id);


--
-- TOC entry 3626 (class 2606 OID 72303)
-- Name: constraints constraints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_pkey PRIMARY KEY (id);


--
-- TOC entry 3633 (class 2606 OID 72305)
-- Name: criteria_weights criteria_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights
    ADD CONSTRAINT criteria_weights_pkey PRIMARY KEY (id);


--
-- TOC entry 3639 (class 2606 OID 72307)
-- Name: criterias criterias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterias
    ADD CONSTRAINT criterias_pkey PRIMARY KEY (id);


--
-- TOC entry 3643 (class 2606 OID 72309)
-- Name: decisions decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decisions
    ADD CONSTRAINT decisions_pkey PRIMARY KEY (id);


--
-- TOC entry 3647 (class 2606 OID 72311)
-- Name: option_categories option_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 3654 (class 2606 OID 72313)
-- Name: option_category_bin_votes option_category_bin_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_pkey PRIMARY KEY (id);


--
-- TOC entry 3662 (class 2606 OID 72315)
-- Name: option_category_range_votes option_category_range_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_pkey PRIMARY KEY (id);


--
-- TOC entry 3669 (class 2606 OID 72317)
-- Name: option_category_weights option_category_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights
    ADD CONSTRAINT option_category_weights_pkey PRIMARY KEY (id);


--
-- TOC entry 3674 (class 2606 OID 72319)
-- Name: option_detail_values option_detail_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_detail_values
    ADD CONSTRAINT option_detail_values_pkey PRIMARY KEY (option_id, option_detail_id);


--
-- TOC entry 3678 (class 2606 OID 72321)
-- Name: option_details option_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_details
    ADD CONSTRAINT option_details_pkey PRIMARY KEY (id);


--
-- TOC entry 3683 (class 2606 OID 72323)
-- Name: option_filters option_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters
    ADD CONSTRAINT option_filters_pkey PRIMARY KEY (id);


--
-- TOC entry 3692 (class 2606 OID 72325)
-- Name: options options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT options_pkey PRIMARY KEY (id);


--
-- TOC entry 3697 (class 2606 OID 72327)
-- Name: participants participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_pkey PRIMARY KEY (id);


--
-- TOC entry 3700 (class 2606 OID 72329)
-- Name: scenario_configs scenario_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_configs
    ADD CONSTRAINT scenario_configs_pkey PRIMARY KEY (id);


--
-- TOC entry 3707 (class 2606 OID 72331)
-- Name: scenario_displays scenario_displays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_pkey PRIMARY KEY (id);


--
-- TOC entry 3714 (class 2606 OID 72333)
-- Name: scenario_sets scenario_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets
    ADD CONSTRAINT scenario_sets_pkey PRIMARY KEY (id);


--
-- TOC entry 3720 (class 2606 OID 72337)
-- Name: scenarios scenarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_pkey PRIMARY KEY (id);


--
-- TOC entry 3725 (class 2606 OID 72339)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3737 (class 2606 OID 79524)
-- Name: solve_dumps solve_dumps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps
    ADD CONSTRAINT solve_dumps_pkey PRIMARY KEY (id);


--
-- TOC entry 3733 (class 2606 OID 72341)
-- Name: variables variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_pkey PRIMARY KEY (id);


--
-- TOC entry 3603 (class 1259 OID 72342)
-- Name: bin_votes_criteria_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_criteria_id_index ON public.bin_votes USING btree (criteria_id);


--
-- TOC entry 3604 (class 1259 OID 72343)
-- Name: bin_votes_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_decision_id_index ON public.bin_votes USING btree (decision_id);


--
-- TOC entry 3605 (class 1259 OID 72344)
-- Name: bin_votes_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_option_id_index ON public.bin_votes USING btree (option_id);


--
-- TOC entry 3606 (class 1259 OID 72345)
-- Name: bin_votes_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_participant_id_index ON public.bin_votes USING btree (participant_id);


--
-- TOC entry 3609 (class 1259 OID 445243)
-- Name: bin_votes_updated_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bin_votes_updated_at_index ON public.bin_votes USING btree (updated_at);


--
-- TOC entry 3611 (class 1259 OID 72346)
-- Name: cache_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cache_decision_id_index ON public.cache USING btree (decision_id);


--
-- TOC entry 3612 (class 1259 OID 72347)
-- Name: cache_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cache_key_index ON public.cache USING btree (key);


--
-- TOC entry 3618 (class 1259 OID 72348)
-- Name: calculations_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX calculations_decision_id_index ON public.calculations USING btree (decision_id);


--
-- TOC entry 3622 (class 1259 OID 72349)
-- Name: constraints_calculation_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX constraints_calculation_id_index ON public.constraints USING btree (calculation_id);


--
-- TOC entry 3623 (class 1259 OID 72350)
-- Name: constraints_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX constraints_decision_id_index ON public.constraints USING btree (decision_id);


--
-- TOC entry 3624 (class 1259 OID 72351)
-- Name: constraints_option_filter_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX constraints_option_filter_id_index ON public.constraints USING btree (option_filter_id);


--
-- TOC entry 3627 (class 1259 OID 72352)
-- Name: constraints_variable_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX constraints_variable_id_index ON public.constraints USING btree (variable_id);


--
-- TOC entry 3629 (class 1259 OID 72353)
-- Name: criteria_weights_criteria_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criteria_weights_criteria_id_index ON public.criteria_weights USING btree (criteria_id);


--
-- TOC entry 3630 (class 1259 OID 72354)
-- Name: criteria_weights_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criteria_weights_decision_id_index ON public.criteria_weights USING btree (decision_id);


--
-- TOC entry 3631 (class 1259 OID 72355)
-- Name: criteria_weights_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criteria_weights_participant_id_index ON public.criteria_weights USING btree (participant_id);


--
-- TOC entry 3634 (class 1259 OID 445246)
-- Name: criteria_weights_updated_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criteria_weights_updated_at_index ON public.criteria_weights USING btree (updated_at);


--
-- TOC entry 3636 (class 1259 OID 72356)
-- Name: criterias_decision_id_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criterias_decision_id_id_index ON public.criterias USING btree (decision_id, id);


--
-- TOC entry 3637 (class 1259 OID 72357)
-- Name: criterias_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX criterias_decision_id_index ON public.criterias USING btree (decision_id);


--
-- TOC entry 3641 (class 1259 OID 975123)
-- Name: decision_keywords; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX decision_keywords ON public.decisions USING gin (keywords);


--
-- TOC entry 3644 (class 1259 OID 72358)
-- Name: decisions_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX decisions_slug_index ON public.decisions USING btree (slug);


--
-- TOC entry 3645 (class 1259 OID 72359)
-- Name: option_categories_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_categories_decision_id_index ON public.option_categories USING btree (decision_id);


--
-- TOC entry 3649 (class 1259 OID 72360)
-- Name: option_category_bin_votes_criteria_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_bin_votes_criteria_id_index ON public.option_category_bin_votes USING btree (criteria_id);


--
-- TOC entry 3650 (class 1259 OID 72361)
-- Name: option_category_bin_votes_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_bin_votes_decision_id_index ON public.option_category_bin_votes USING btree (decision_id);


--
-- TOC entry 3651 (class 1259 OID 72362)
-- Name: option_category_bin_votes_option_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_bin_votes_option_category_id_index ON public.option_category_bin_votes USING btree (option_category_id);


--
-- TOC entry 3652 (class 1259 OID 72363)
-- Name: option_category_bin_votes_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_bin_votes_participant_id_index ON public.option_category_bin_votes USING btree (participant_id);


--
-- TOC entry 3656 (class 1259 OID 72364)
-- Name: option_category_range_votes_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_decision_id_index ON public.option_category_range_votes USING btree (decision_id);


--
-- TOC entry 3657 (class 1259 OID 72365)
-- Name: option_category_range_votes_high_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_high_option_id_index ON public.option_category_range_votes USING btree (high_option_id);


--
-- TOC entry 3658 (class 1259 OID 72366)
-- Name: option_category_range_votes_low_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_low_option_id_index ON public.option_category_range_votes USING btree (low_option_id);


--
-- TOC entry 3659 (class 1259 OID 72367)
-- Name: option_category_range_votes_option_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_option_category_id_index ON public.option_category_range_votes USING btree (option_category_id);


--
-- TOC entry 3660 (class 1259 OID 72368)
-- Name: option_category_range_votes_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_participant_id_index ON public.option_category_range_votes USING btree (participant_id);


--
-- TOC entry 3663 (class 1259 OID 445245)
-- Name: option_category_range_votes_updated_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_range_votes_updated_at_index ON public.option_category_range_votes USING btree (updated_at);


--
-- TOC entry 3665 (class 1259 OID 72369)
-- Name: option_category_weights_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_weights_decision_id_index ON public.option_category_weights USING btree (decision_id);


--
-- TOC entry 3666 (class 1259 OID 72370)
-- Name: option_category_weights_option_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_weights_option_category_id_index ON public.option_category_weights USING btree (option_category_id);


--
-- TOC entry 3667 (class 1259 OID 72371)
-- Name: option_category_weights_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_weights_participant_id_index ON public.option_category_weights USING btree (participant_id);


--
-- TOC entry 3670 (class 1259 OID 445244)
-- Name: option_category_weights_updated_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_category_weights_updated_at_index ON public.option_category_weights USING btree (updated_at);


--
-- TOC entry 3672 (class 1259 OID 72372)
-- Name: option_detail_values_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_detail_values_decision_id_index ON public.option_detail_values USING btree (decision_id);


--
-- TOC entry 3675 (class 1259 OID 72373)
-- Name: option_details_decision_id_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_details_decision_id_id_index ON public.option_details USING btree (decision_id, id);


--
-- TOC entry 3676 (class 1259 OID 72374)
-- Name: option_details_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_details_decision_id_index ON public.option_details USING btree (decision_id);


--
-- TOC entry 3680 (class 1259 OID 72375)
-- Name: option_filters_decision_id_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_filters_decision_id_id_index ON public.option_filters USING btree (decision_id, id);


--
-- TOC entry 3681 (class 1259 OID 72376)
-- Name: option_filters_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX option_filters_decision_id_index ON public.option_filters USING btree (decision_id);


--
-- TOC entry 3688 (class 1259 OID 72377)
-- Name: options_decision_id_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX options_decision_id_id_index ON public.options USING btree (decision_id, id);


--
-- TOC entry 3689 (class 1259 OID 72378)
-- Name: options_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX options_decision_id_index ON public.options USING btree (decision_id);


--
-- TOC entry 3690 (class 1259 OID 72379)
-- Name: options_option_category_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX options_option_category_id_index ON public.options USING btree (option_category_id);


--
-- TOC entry 3694 (class 1259 OID 72380)
-- Name: participants_auxiliary_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX participants_auxiliary_index ON public.participants USING btree (auxiliary);


--
-- TOC entry 3695 (class 1259 OID 72381)
-- Name: participants_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX participants_decision_id_index ON public.participants USING btree (decision_id);


--
-- TOC entry 3698 (class 1259 OID 72382)
-- Name: scenario_configs_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_configs_decision_id_index ON public.scenario_configs USING btree (decision_id);


--
-- TOC entry 3702 (class 1259 OID 592068)
-- Name: scenario_displays_calculation_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_calculation_id_index ON public.scenario_displays USING btree (calculation_id);


--
-- TOC entry 3703 (class 1259 OID 592074)
-- Name: scenario_displays_constraint_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_constraint_id_index ON public.scenario_displays USING btree (constraint_id);


--
-- TOC entry 3704 (class 1259 OID 409275)
-- Name: scenario_displays_decision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_decision_id ON public.scenario_displays USING btree (decision_id);


--
-- TOC entry 3705 (class 1259 OID 72385)
-- Name: scenario_displays_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_name_index ON public.scenario_displays USING btree (name);


--
-- TOC entry 3708 (class 1259 OID 72386)
-- Name: scenario_displays_scenario_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_displays_scenario_id_index ON public.scenario_displays USING btree (scenario_id);


--
-- TOC entry 3709 (class 1259 OID 72387)
-- Name: scenario_sets_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_decision_id_index ON public.scenario_sets USING btree (decision_id);


--
-- TOC entry 3710 (class 1259 OID 354755)
-- Name: scenario_sets_decision_id_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_decision_id_status_index ON public.scenario_sets USING btree (decision_id, status);


--
-- TOC entry 3711 (class 1259 OID 72388)
-- Name: scenario_sets_hash_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_hash_index ON public.scenario_sets USING btree (hash);


--
-- TOC entry 3712 (class 1259 OID 72389)
-- Name: scenario_sets_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_participant_id_index ON public.scenario_sets USING btree (participant_id);


--
-- TOC entry 3715 (class 1259 OID 592080)
-- Name: scenario_sets_scenario_config_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenario_sets_scenario_config_id_index ON public.scenario_sets USING btree (scenario_config_id);


--
-- TOC entry 3716 (class 1259 OID 409281)
-- Name: scenarios_decision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_decision_id ON public.scenarios USING btree (decision_id);


--
-- TOC entry 3717 (class 1259 OID 72436)
-- Name: scenarios_global_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_global_index ON public.scenarios USING btree (global);


--
-- TOC entry 3718 (class 1259 OID 72437)
-- Name: scenarios_minimize_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_minimize_index ON public.scenarios USING btree (minimize);


--
-- TOC entry 3723 (class 1259 OID 402351)
-- Name: scenarios_options_scenario_id_option_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_options_scenario_id_option_id_index ON public.scenarios_options USING btree (scenario_id, option_id);


--
-- TOC entry 3721 (class 1259 OID 72438)
-- Name: scenarios_scenario_set_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_scenario_set_id_index ON public.scenarios USING btree (scenario_set_id);


--
-- TOC entry 3722 (class 1259 OID 72439)
-- Name: scenarios_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scenarios_status_index ON public.scenarios USING btree (status);


--
-- TOC entry 3734 (class 1259 OID 79540)
-- Name: solve_dumps_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX solve_dumps_decision_id_index ON public.solve_dumps USING btree (decision_id);


--
-- TOC entry 3735 (class 1259 OID 79541)
-- Name: solve_dumps_participant_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX solve_dumps_participant_id_index ON public.solve_dumps USING btree (participant_id);


--
-- TOC entry 3684 (class 1259 OID 72440)
-- Name: unique_all_options; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_all_options ON public.option_filters USING btree (decision_id, match_mode) WHERE ((match_mode)::text = 'all_options'::text);


--
-- TOC entry 3615 (class 1259 OID 72441)
-- Name: unique_cache_decision_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_cache_decision_key ON public.cache USING btree (decision_id, key);


--
-- TOC entry 3621 (class 1259 OID 72442)
-- Name: unique_calculation_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_calculation_slug_index ON public.calculations USING btree (decision_id, slug);


--
-- TOC entry 3628 (class 1259 OID 72443)
-- Name: unique_constraint_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_constraint_slug_index ON public.constraints USING btree (decision_id, slug);


--
-- TOC entry 3640 (class 1259 OID 72444)
-- Name: unique_criteria_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_criteria_slug_index ON public.criterias USING btree (decision_id, slug);


--
-- TOC entry 3726 (class 1259 OID 72445)
-- Name: unique_detail_variable_config_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_detail_variable_config_index ON public.variables USING btree (option_detail_id, method);


--
-- TOC entry 3727 (class 1259 OID 72446)
-- Name: unique_filter_variable_config_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_filter_variable_config_index ON public.variables USING btree (option_filter_id, method);


--
-- TOC entry 3648 (class 1259 OID 72447)
-- Name: unique_option_category_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_category_slug_index ON public.option_categories USING btree (decision_id, slug);


--
-- TOC entry 3679 (class 1259 OID 72448)
-- Name: unique_option_detail_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_detail_slug_index ON public.option_details USING btree (decision_id, slug);


--
-- TOC entry 3685 (class 1259 OID 72449)
-- Name: unique_option_filter_category_config_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_filter_category_config_index ON public.option_filters USING btree (option_category_id, match_mode);


--
-- TOC entry 3686 (class 1259 OID 72450)
-- Name: unique_option_filter_detail_config_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_filter_detail_config_index ON public.option_filters USING btree (option_detail_id, match_mode, match_value);


--
-- TOC entry 3687 (class 1259 OID 72451)
-- Name: unique_option_filter_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_filter_slug_index ON public.option_filters USING btree (decision_id, slug);


--
-- TOC entry 3693 (class 1259 OID 72452)
-- Name: unique_option_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_option_slug_index ON public.options USING btree (decision_id, slug);


--
-- TOC entry 3655 (class 1259 OID 72453)
-- Name: unique_p_oc_bin_vote_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_p_oc_bin_vote_index ON public.option_category_bin_votes USING btree (criteria_id, participant_id, option_category_id);


--
-- TOC entry 3664 (class 1259 OID 72454)
-- Name: unique_p_oc_range_vote; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_p_oc_range_vote ON public.option_category_range_votes USING btree (participant_id, option_category_id);


--
-- TOC entry 3610 (class 1259 OID 72455)
-- Name: unique_participant_bin_vote_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_participant_bin_vote_index ON public.bin_votes USING btree (criteria_id, participant_id, option_id);


--
-- TOC entry 3635 (class 1259 OID 72456)
-- Name: unique_participant_criteria_weight_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_participant_criteria_weight_index ON public.criteria_weights USING btree (criteria_id, participant_id);


--
-- TOC entry 3671 (class 1259 OID 72457)
-- Name: unique_participant_filter_weight_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_participant_filter_weight_index ON public.option_category_weights USING btree (option_category_id, participant_id);


--
-- TOC entry 3701 (class 1259 OID 72458)
-- Name: unique_scenario_config_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_scenario_config_slug_index ON public.scenario_configs USING btree (decision_id, slug);


--
-- TOC entry 3738 (class 1259 OID 1177387)
-- Name: unique_scenario_set_solve_dump; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_scenario_set_solve_dump ON public.solve_dumps USING btree (scenario_set_id);


--
-- TOC entry 3728 (class 1259 OID 72459)
-- Name: unique_variable_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_variable_slug_index ON public.variables USING btree (decision_id, slug);


--
-- TOC entry 3729 (class 1259 OID 72460)
-- Name: variables_decision_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX variables_decision_id_index ON public.variables USING btree (decision_id);


--
-- TOC entry 3730 (class 1259 OID 72461)
-- Name: variables_option_detail_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX variables_option_detail_id_index ON public.variables USING btree (option_detail_id);


--
-- TOC entry 3731 (class 1259 OID 72462)
-- Name: variables_option_filter_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX variables_option_filter_id_index ON public.variables USING btree (option_filter_id);


--
-- TOC entry 3739 (class 2606 OID 72463)
-- Name: bin_votes bin_votes_criteria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_criteria_id_fkey FOREIGN KEY (criteria_id) REFERENCES public.criterias(id) ON DELETE CASCADE;


--
-- TOC entry 3740 (class 2606 OID 72468)
-- Name: bin_votes bin_votes_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3741 (class 2606 OID 72473)
-- Name: bin_votes bin_votes_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- TOC entry 3742 (class 2606 OID 72478)
-- Name: bin_votes bin_votes_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bin_votes
    ADD CONSTRAINT bin_votes_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- TOC entry 3743 (class 2606 OID 72483)
-- Name: cache cache_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3744 (class 2606 OID 72488)
-- Name: calculation_variables calculation_variables_calculation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculation_variables
    ADD CONSTRAINT calculation_variables_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES public.calculations(id) ON DELETE CASCADE;


--
-- TOC entry 3745 (class 2606 OID 72493)
-- Name: calculation_variables calculation_variables_variable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculation_variables
    ADD CONSTRAINT calculation_variables_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.variables(id) ON DELETE CASCADE;


--
-- TOC entry 3746 (class 2606 OID 72498)
-- Name: calculations calculations_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calculations
    ADD CONSTRAINT calculations_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3747 (class 2606 OID 72503)
-- Name: constraints constraints_calculation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES public.calculations(id) ON DELETE CASCADE;


--
-- TOC entry 3748 (class 2606 OID 72508)
-- Name: constraints constraints_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3749 (class 2606 OID 72513)
-- Name: constraints constraints_option_filter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_option_filter_id_fkey FOREIGN KEY (option_filter_id) REFERENCES public.option_filters(id) ON DELETE CASCADE;


--
-- TOC entry 3750 (class 2606 OID 72518)
-- Name: constraints constraints_variable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.constraints
    ADD CONSTRAINT constraints_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.variables(id) ON DELETE CASCADE;


--
-- TOC entry 3751 (class 2606 OID 72523)
-- Name: criteria_weights criteria_weights_criteria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights
    ADD CONSTRAINT criteria_weights_criteria_id_fkey FOREIGN KEY (criteria_id) REFERENCES public.criterias(id) ON DELETE CASCADE;


--
-- TOC entry 3752 (class 2606 OID 72528)
-- Name: criteria_weights criteria_weights_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights
    ADD CONSTRAINT criteria_weights_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3753 (class 2606 OID 72533)
-- Name: criteria_weights criteria_weights_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criteria_weights
    ADD CONSTRAINT criteria_weights_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- TOC entry 3754 (class 2606 OID 72538)
-- Name: criterias criterias_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterias
    ADD CONSTRAINT criterias_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3755 (class 2606 OID 72543)
-- Name: option_categories option_categories_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3756 (class 2606 OID 72548)
-- Name: option_categories option_categories_default_high_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_default_high_option_id_fkey FOREIGN KEY (default_high_option_id) REFERENCES public.options(id) ON DELETE SET NULL;


--
-- TOC entry 3757 (class 2606 OID 72553)
-- Name: option_categories option_categories_default_low_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_default_low_option_id_fkey FOREIGN KEY (default_low_option_id) REFERENCES public.options(id) ON DELETE SET NULL;


--
-- TOC entry 3758 (class 2606 OID 72558)
-- Name: option_categories option_categories_primary_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_categories
    ADD CONSTRAINT option_categories_primary_detail_id_fkey FOREIGN KEY (primary_detail_id) REFERENCES public.option_details(id) ON DELETE SET NULL;


--
-- TOC entry 3759 (class 2606 OID 72563)
-- Name: option_category_bin_votes option_category_bin_votes_criteria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_criteria_id_fkey FOREIGN KEY (criteria_id) REFERENCES public.criterias(id) ON DELETE CASCADE;


--
-- TOC entry 3760 (class 2606 OID 72568)
-- Name: option_category_bin_votes option_category_bin_votes_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3761 (class 2606 OID 72573)
-- Name: option_category_bin_votes option_category_bin_votes_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- TOC entry 3762 (class 2606 OID 72578)
-- Name: option_category_bin_votes option_category_bin_votes_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_bin_votes
    ADD CONSTRAINT option_category_bin_votes_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- TOC entry 3763 (class 2606 OID 72583)
-- Name: option_category_range_votes option_category_range_votes_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3764 (class 2606 OID 72588)
-- Name: option_category_range_votes option_category_range_votes_high_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_high_option_id_fkey FOREIGN KEY (high_option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- TOC entry 3765 (class 2606 OID 72593)
-- Name: option_category_range_votes option_category_range_votes_low_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_low_option_id_fkey FOREIGN KEY (low_option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- TOC entry 3766 (class 2606 OID 72598)
-- Name: option_category_range_votes option_category_range_votes_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- TOC entry 3767 (class 2606 OID 72603)
-- Name: option_category_range_votes option_category_range_votes_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_range_votes
    ADD CONSTRAINT option_category_range_votes_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- TOC entry 3768 (class 2606 OID 72608)
-- Name: option_category_weights option_category_weights_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights
    ADD CONSTRAINT option_category_weights_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3769 (class 2606 OID 72613)
-- Name: option_category_weights option_category_weights_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights
    ADD CONSTRAINT option_category_weights_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- TOC entry 3770 (class 2606 OID 72618)
-- Name: option_category_weights option_category_weights_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_category_weights
    ADD CONSTRAINT option_category_weights_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- TOC entry 3771 (class 2606 OID 72623)
-- Name: option_detail_values option_detail_values_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_detail_values
    ADD CONSTRAINT option_detail_values_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3772 (class 2606 OID 72628)
-- Name: option_detail_values option_detail_values_option_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_detail_values
    ADD CONSTRAINT option_detail_values_option_detail_id_fkey FOREIGN KEY (option_detail_id) REFERENCES public.option_details(id) ON DELETE CASCADE;


--
-- TOC entry 3773 (class 2606 OID 72633)
-- Name: option_detail_values option_detail_values_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_detail_values
    ADD CONSTRAINT option_detail_values_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- TOC entry 3774 (class 2606 OID 72638)
-- Name: option_details option_details_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_details
    ADD CONSTRAINT option_details_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3775 (class 2606 OID 72643)
-- Name: option_filters option_filters_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters
    ADD CONSTRAINT option_filters_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3776 (class 2606 OID 72648)
-- Name: option_filters option_filters_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters
    ADD CONSTRAINT option_filters_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE CASCADE;


--
-- TOC entry 3777 (class 2606 OID 72653)
-- Name: option_filters option_filters_option_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_filters
    ADD CONSTRAINT option_filters_option_detail_id_fkey FOREIGN KEY (option_detail_id) REFERENCES public.option_details(id) ON DELETE CASCADE;


--
-- TOC entry 3778 (class 2606 OID 72658)
-- Name: options options_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT options_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3779 (class 2606 OID 72663)
-- Name: options options_option_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.options
    ADD CONSTRAINT options_option_category_id_fkey FOREIGN KEY (option_category_id) REFERENCES public.option_categories(id) ON DELETE SET NULL;


--
-- TOC entry 3780 (class 2606 OID 72668)
-- Name: participants participants_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3781 (class 2606 OID 72673)
-- Name: scenario_configs scenario_configs_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_configs
    ADD CONSTRAINT scenario_configs_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3782 (class 2606 OID 592069)
-- Name: scenario_displays scenario_displays_calculation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_calculation_id_fkey FOREIGN KEY (calculation_id) REFERENCES public.calculations(id) ON DELETE CASCADE;


--
-- TOC entry 3783 (class 2606 OID 592075)
-- Name: scenario_displays scenario_displays_constraint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_constraint_id_fkey FOREIGN KEY (constraint_id) REFERENCES public.constraints(id) ON DELETE CASCADE;


--
-- TOC entry 3784 (class 2606 OID 409276)
-- Name: scenario_displays scenario_displays_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3785 (class 2606 OID 72688)
-- Name: scenario_displays scenario_displays_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_displays
    ADD CONSTRAINT scenario_displays_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.scenarios(id) ON DELETE CASCADE;


--
-- TOC entry 3786 (class 2606 OID 72693)
-- Name: scenario_sets scenario_sets_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets
    ADD CONSTRAINT scenario_sets_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3787 (class 2606 OID 72698)
-- Name: scenario_sets scenario_sets_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets
    ADD CONSTRAINT scenario_sets_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- TOC entry 3788 (class 2606 OID 592081)
-- Name: scenario_sets scenario_sets_scenario_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenario_sets
    ADD CONSTRAINT scenario_sets_scenario_config_id_fkey FOREIGN KEY (scenario_config_id) REFERENCES public.scenario_configs(id) ON DELETE CASCADE;


--
-- TOC entry 3789 (class 2606 OID 409282)
-- Name: scenarios scenarios_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3791 (class 2606 OID 72733)
-- Name: scenarios_options scenarios_options_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios_options
    ADD CONSTRAINT scenarios_options_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.options(id) ON DELETE CASCADE;


--
-- TOC entry 3792 (class 2606 OID 72738)
-- Name: scenarios_options scenarios_options_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios_options
    ADD CONSTRAINT scenarios_options_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.scenarios(id) ON DELETE CASCADE;


--
-- TOC entry 3790 (class 2606 OID 72743)
-- Name: scenarios scenarios_scenario_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scenarios
    ADD CONSTRAINT scenarios_scenario_set_id_fkey FOREIGN KEY (scenario_set_id) REFERENCES public.scenario_sets(id) ON DELETE CASCADE;


--
-- TOC entry 3796 (class 2606 OID 79525)
-- Name: solve_dumps solve_dumps_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps
    ADD CONSTRAINT solve_dumps_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3797 (class 2606 OID 79530)
-- Name: solve_dumps solve_dumps_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps
    ADD CONSTRAINT solve_dumps_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id) ON DELETE CASCADE;


--
-- TOC entry 3798 (class 2606 OID 79535)
-- Name: solve_dumps solve_dumps_scenario_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solve_dumps
    ADD CONSTRAINT solve_dumps_scenario_set_id_fkey FOREIGN KEY (scenario_set_id) REFERENCES public.scenario_sets(id) ON DELETE CASCADE;


--
-- TOC entry 3793 (class 2606 OID 72748)
-- Name: variables variables_decision_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES public.decisions(id) ON DELETE CASCADE;


--
-- TOC entry 3794 (class 2606 OID 72753)
-- Name: variables variables_option_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_option_detail_id_fkey FOREIGN KEY (option_detail_id) REFERENCES public.option_details(id) ON DELETE CASCADE;


--
-- TOC entry 3795 (class 2606 OID 72758)
-- Name: variables variables_option_filter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variables
    ADD CONSTRAINT variables_option_filter_id_fkey FOREIGN KEY (option_filter_id) REFERENCES public.option_filters(id) ON DELETE CASCADE;


-- Completed on 2024-08-01 14:51:44 PDT

--
-- PostgreSQL database dump complete
--

