SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_levels (
    id bigint NOT NULL,
    value character varying,
    description character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: access_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.access_levels_id_seq OWNED BY public.access_levels.id;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    id bigint NOT NULL,
    addressable_type character varying,
    addressable_id bigint,
    add1 character varying,
    add2 character varying,
    city character varying,
    postcode character varying,
    telephone character varying,
    dateofaddress date,
    country_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    default_address boolean
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;


--
-- Name: advisory_committees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.advisory_committees (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: advisory_committees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.advisory_committees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: advisory_committees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.advisory_committees_id_seq OWNED BY public.advisory_committees.id;


--
-- Name: amendment_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.amendment_types (
    id bigint NOT NULL,
    value character varying
);


--
-- Name: amendment_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.amendment_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: amendment_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.amendment_types_id_seq OWNED BY public.amendment_types.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: birth_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.birth_data (
    birth_dataid bigint NOT NULL,
    ppatient_id bigint,
    birthwgt character varying,
    caind character varying,
    ccgpob character varying,
    cestrss character varying,
    ctypob character varying,
    dobf character varying,
    dor character varying,
    esttypeb character varying,
    hautpob character varying,
    hropob character varying,
    loarpob character varying,
    lsoarpob character varying,
    multbth integer,
    multtype character varying,
    nhsind integer,
    cod10r_1 character varying,
    cod10r_2 character varying,
    cod10r_3 character varying,
    cod10r_4 character varying,
    cod10r_5 character varying,
    cod10r_6 character varying,
    cod10r_7 character varying,
    cod10r_8 character varying,
    cod10r_9 character varying,
    cod10r_10 character varying,
    cod10r_11 character varying,
    cod10r_12 character varying,
    cod10r_13 character varying,
    cod10r_14 character varying,
    cod10r_15 character varying,
    cod10r_16 character varying,
    cod10r_17 character varying,
    cod10r_18 character varying,
    cod10r_19 character varying,
    cod10r_20 character varying,
    wigwo10 integer,
    agebf character varying,
    agebm character varying,
    agemf character varying,
    agemm character varying,
    bthimar character varying,
    ccgrm character varying,
    ctrypobf character varying,
    ctrypobm character varying,
    ctydrm character varying,
    ctyrm character varying,
    durmar character varying,
    empsecf character varying,
    empsecm character varying,
    empstf character varying,
    empstm character varying,
    gorrm character varying,
    hautrm character varying,
    hrorm character varying,
    loarm character varying,
    lsoarm character varying,
    seccatf character varying,
    seccatm character varying,
    soc2kf character varying,
    soc2km character varying,
    soc90f character varying,
    soc90m character varying,
    stregrm character varying,
    wardrm character varying,
    ccg9pob character varying,
    ccg9rm character varying,
    gor9rm character varying,
    ward9m character varying,
    mattab integer
);


--
-- Name: birth_data_birth_dataid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.birth_data_birth_dataid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: birth_data_birth_dataid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.birth_data_birth_dataid_seq OWNED BY public.birth_data.birth_dataid;


--
-- Name: cas_application_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_application_fields (
    id bigint NOT NULL,
    project_id bigint,
    status character varying,
    address text,
    n3_ip_address text,
    reason_justification text,
    access_level character varying,
    extra_datasets character varying,
    extra_datasets_rationale character varying,
    declaration character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    organisation character varying,
    username character varying,
    contract_enddate date,
    contract_startdate date,
    employee_type character varying,
    line_manager_number character varying,
    line_manager_email character varying,
    line_manager_name character varying,
    work_number character varying,
    phe_email character varying,
    jobtitle character varying,
    surname character varying,
    firstname character varying
);


--
-- Name: cas_application_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_application_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_application_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_application_fields_id_seq OWNED BY public.cas_application_fields.id;


--
-- Name: cas_declarations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_declarations (
    id bigint NOT NULL,
    value text,
    sort integer
);


--
-- Name: cas_declarations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_declarations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_declarations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_declarations_id_seq OWNED BY public.cas_declarations.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    dataset_version_id integer,
    sort integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    core boolean
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: choice_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.choice_types (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: choice_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.choice_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: choice_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.choice_types_id_seq OWNED BY public.choice_types.id;


--
-- Name: classifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classifications (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: classifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.classifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.classifications_id_seq OWNED BY public.classifications.id;


--
-- Name: closure_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.closure_reasons (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: closure_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.closure_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: closure_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.closure_reasons_id_seq OWNED BY public.closure_reasons.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL,
    commentable_type character varying NOT NULL,
    commentable_id bigint NOT NULL,
    body character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: common_law_exemptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.common_law_exemptions (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: common_law_exemptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.common_law_exemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: common_law_exemptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.common_law_exemptions_id_seq OWNED BY public.common_law_exemptions.id;


--
-- Name: communications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.communications (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    project_id bigint NOT NULL,
    parent_id bigint,
    sender_id bigint NOT NULL,
    recipient_id bigint NOT NULL,
    medium smallint NOT NULL,
    contacted_at timestamp without time zone NOT NULL
);


--
-- Name: communications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.communications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: communications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.communications_id_seq OWNED BY public.communications.id;


--
-- Name: contract_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contract_types (
    id bigint NOT NULL,
    value character varying
);


--
-- Name: contract_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contract_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contract_types_id_seq OWNED BY public.contract_types.id;


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contracts (
    id bigint NOT NULL,
    project_id bigint,
    data_sharing_contract_ref character varying,
    dra_start timestamp without time zone,
    dra_end timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    contract_type character varying,
    contract_version character varying,
    contract_status character varying,
    project_state_id bigint,
    contract_sent_date timestamp without time zone,
    contract_start_date timestamp without time zone,
    contract_end_date timestamp without time zone,
    contract_returned_date timestamp without time zone,
    contract_executed_date timestamp without time zone,
    advisory_letter_date timestamp without time zone,
    destruction_form_received_date timestamp without time zone,
    reference character varying,
    referent_type character varying NOT NULL,
    referent_id bigint NOT NULL,
    referent_reference character varying
);


--
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contracts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contracts_id_seq OWNED BY public.contracts.id;


--
-- Name: cost_recoveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cost_recoveries (
    id bigint NOT NULL,
    project_id bigint,
    cost_recovery_applied boolean DEFAULT false,
    quote_cost numeric(8,2),
    actual_cost numeric(8,2),
    invoice_request_date timestamp without time zone,
    phe_customer_number character varying,
    purchase_order_number character varying,
    phe_invoice_number character varying,
    invoiced_financial_year character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cost_recoveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cost_recoveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cost_recoveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cost_recoveries_id_seq OWNED BY public.cost_recoveries.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    id character varying(3) NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: data_dictionary_elements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_dictionary_elements (
    id bigint NOT NULL,
    name character varying,
    "group" character varying,
    status character varying,
    format_length character varying,
    national_codes character varying,
    link character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    xml_type_id integer
);


--
-- Name: data_dictionary_elements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_dictionary_elements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_dictionary_elements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_dictionary_elements_id_seq OWNED BY public.data_dictionary_elements.id;


--
-- Name: data_item_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_item_groups (
    id bigint NOT NULL,
    data_item_id bigint,
    group_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: data_item_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_item_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_item_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_item_groups_id_seq OWNED BY public.data_item_groups.id;


--
-- Name: data_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_items (
    id bigint NOT NULL,
    name character varying,
    identifier character varying,
    annotation character varying,
    description character varying,
    min_occurs integer,
    max_occurs integer,
    common boolean,
    entity_id integer,
    xml_type_id integer,
    data_dictionary_element_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: data_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_items_id_seq OWNED BY public.data_items.id;


--
-- Name: data_privacy_impact_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_privacy_impact_assessments (
    id bigint NOT NULL,
    project_id bigint,
    project_state_id bigint,
    ig_toolkit_version character varying,
    ig_score integer,
    ig_assessment_status_id bigint,
    review_meeting_date timestamp without time zone,
    dpia_decision_date timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    reference character varying,
    referent_type character varying NOT NULL,
    referent_id bigint NOT NULL,
    referent_reference character varying
);


--
-- Name: data_privacy_impact_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_privacy_impact_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_privacy_impact_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_privacy_impact_assessments_id_seq OWNED BY public.data_privacy_impact_assessments.id;


--
-- Name: data_source_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_source_items (
    id integer NOT NULL,
    name character varying,
    description character varying,
    governance character varying,
    data_source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    occurrences integer,
    category character varying
);


--
-- Name: data_source_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_source_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_source_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_source_items_id_seq OWNED BY public.data_source_items.id;


--
-- Name: data_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_sources (
    id integer NOT NULL,
    name character varying,
    title character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms text
);


--
-- Name: data_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_sources_id_seq OWNED BY public.data_sources.id;


--
-- Name: dataset_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_roles (
    id bigint NOT NULL,
    name character varying,
    startdate timestamp without time zone,
    enddate timestamp without time zone,
    sort integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dataset_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dataset_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dataset_roles_id_seq OWNED BY public.dataset_roles.id;


--
-- Name: dataset_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_types (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dataset_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dataset_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dataset_types_id_seq OWNED BY public.dataset_types.id;


--
-- Name: dataset_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dataset_versions (
    id bigint NOT NULL,
    dataset_id integer,
    semver_version character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    published boolean DEFAULT false
);


--
-- Name: dataset_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dataset_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dataset_versions_id_seq OWNED BY public.dataset_versions.id;


--
-- Name: datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.datasets (
    id bigint NOT NULL,
    name character varying,
    full_name character varying,
    description character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms character varying(999),
    dataset_type_id integer,
    team_id integer,
    levels jsonb DEFAULT '{}'::jsonb NOT NULL,
    cas_type smallint
);


--
-- Name: datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.datasets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.datasets_id_seq OWNED BY public.datasets.id;


--
-- Name: death_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.death_data (
    death_dataid bigint NOT NULL,
    ppatient_id bigint,
    cestrssr character varying,
    ceststay character varying,
    ccgpod character varying,
    cestrss character varying,
    cod10r_1 character varying,
    cod10r_2 character varying,
    cod10r_3 character varying,
    cod10r_4 character varying,
    cod10r_5 character varying,
    cod10r_6 character varying,
    cod10r_7 character varying,
    cod10r_8 character varying,
    cod10r_9 character varying,
    cod10r_10 character varying,
    cod10r_11 character varying,
    cod10r_12 character varying,
    cod10r_13 character varying,
    cod10r_14 character varying,
    cod10r_15 character varying,
    cod10r_16 character varying,
    cod10r_17 character varying,
    cod10r_18 character varying,
    cod10r_19 character varying,
    cod10r_20 character varying,
    cod10rf_1 character varying,
    cod10rf_2 character varying,
    cod10rf_3 character varying,
    cod10rf_4 character varying,
    cod10rf_5 character varying,
    cod10rf_6 character varying,
    cod10rf_7 character varying,
    cod10rf_8 character varying,
    cod10rf_9 character varying,
    cod10rf_10 character varying,
    cod10rf_11 character varying,
    cod10rf_12 character varying,
    cod10rf_13 character varying,
    cod10rf_14 character varying,
    cod10rf_15 character varying,
    cod10rf_16 character varying,
    cod10rf_17 character varying,
    cod10rf_18 character varying,
    cod10rf_19 character varying,
    cod10rf_20 character varying,
    codt_1 character varying,
    codt_2 character varying,
    codt_3 character varying,
    codt_4 character varying,
    codt_5 character varying,
    ctydpod character varying,
    ctypod character varying,
    dester character varying,
    doddy character varying,
    dodmt character varying,
    dodyr integer,
    esttyped character varying,
    hautpod character varying,
    hropod character varying,
    icd_1 character varying,
    icd_2 character varying,
    icd_3 character varying,
    icd_4 character varying,
    icd_5 character varying,
    icd_6 character varying,
    icd_7 character varying,
    icd_8 character varying,
    icd_9 character varying,
    icd_10 character varying,
    icd_11 character varying,
    icd_12 character varying,
    icd_13 character varying,
    icd_14 character varying,
    icd_15 character varying,
    icd_16 character varying,
    icd_17 character varying,
    icd_18 character varying,
    icd_19 character varying,
    icd_20 character varying,
    icdf_1 character varying,
    icdf_2 character varying,
    icdf_3 character varying,
    icdf_4 character varying,
    icdf_5 character varying,
    icdf_6 character varying,
    icdf_7 character varying,
    icdf_8 character varying,
    icdf_9 character varying,
    icdf_10 character varying,
    icdf_11 character varying,
    icdf_12 character varying,
    icdf_13 character varying,
    icdf_14 character varying,
    icdf_15 character varying,
    icdf_16 character varying,
    icdf_17 character varying,
    icdf_18 character varying,
    icdf_19 character varying,
    icdf_20 character varying,
    icdpv_1 character varying,
    icdpv_2 character varying,
    icdpv_3 character varying,
    icdpv_4 character varying,
    icdpv_5 character varying,
    icdpv_6 character varying,
    icdpv_7 character varying,
    icdpv_8 character varying,
    icdpv_9 character varying,
    icdpv_10 character varying,
    icdpv_11 character varying,
    icdpv_12 character varying,
    icdpv_13 character varying,
    icdpv_14 character varying,
    icdpv_15 character varying,
    icdpv_16 character varying,
    icdpv_17 character varying,
    icdpv_18 character varying,
    icdpv_19 character varying,
    icdpv_20 character varying,
    icdpvf_1 character varying,
    icdpvf_2 character varying,
    icdpvf_3 character varying,
    icdpvf_4 character varying,
    icdpvf_5 character varying,
    icdpvf_6 character varying,
    icdpvf_7 character varying,
    icdpvf_8 character varying,
    icdpvf_9 character varying,
    icdpvf_10 character varying,
    icdpvf_11 character varying,
    icdpvf_12 character varying,
    icdpvf_13 character varying,
    icdpvf_14 character varying,
    icdpvf_15 character varying,
    icdpvf_16 character varying,
    icdpvf_17 character varying,
    icdpvf_18 character varying,
    icdpvf_19 character varying,
    icdpvf_20 character varying,
    icdsc character varying,
    icdscf character varying,
    icdu character varying,
    icduf character varying,
    icdfuture1 character varying,
    icdfuture2 character varying,
    lineno9_1 integer,
    lineno9_2 integer,
    lineno9_3 integer,
    lineno9_4 integer,
    lineno9_5 integer,
    lineno9_6 integer,
    lineno9_7 integer,
    lineno9_8 integer,
    lineno9_9 integer,
    lineno9_10 integer,
    lineno9_11 integer,
    lineno9_12 integer,
    lineno9_13 integer,
    lineno9_14 integer,
    lineno9_15 integer,
    lineno9_16 integer,
    lineno9_17 integer,
    lineno9_18 integer,
    lineno9_19 integer,
    lineno9_20 integer,
    lineno9f_1 integer,
    lineno9f_2 integer,
    lineno9f_3 integer,
    lineno9f_4 integer,
    lineno9f_5 integer,
    lineno9f_6 integer,
    lineno9f_7 integer,
    lineno9f_8 integer,
    lineno9f_9 integer,
    lineno9f_10 integer,
    lineno9f_11 integer,
    lineno9f_12 integer,
    lineno9f_13 integer,
    lineno9f_14 integer,
    lineno9f_15 integer,
    lineno9f_16 integer,
    lineno9f_17 integer,
    lineno9f_18 integer,
    lineno9f_19 integer,
    lineno9f_20 integer,
    loapod character varying,
    lsoapod character varying,
    nhsind character varying,
    ploacc10 character varying,
    podqual character varying,
    podt character varying,
    wigwo10 character varying,
    wigwo10f character varying,
    agecunit integer,
    ccgr character varying,
    ctrypob character varying,
    ctryr character varying,
    ctydr character varying,
    ctyr character varying,
    gorr character varying,
    hautr character varying,
    hror character varying,
    loar character varying,
    lsoar character varying,
    marstat character varying,
    occdt character varying,
    occfft_1 character varying,
    occfft_2 character varying,
    occfft_3 character varying,
    occfft_4 character varying,
    occtype character varying,
    wardr character varying,
    emprssdm character varying,
    emprsshf character varying,
    empsecdm character varying,
    empsechf character varying,
    empstdm character varying,
    empsthf character varying,
    inddmt character varying,
    indhft character varying,
    occ90dm character varying,
    occ90hf character varying,
    occhft character varying,
    occmt character varying,
    retindm character varying,
    retindhf character varying,
    sclasdm character varying,
    sclashf character varying,
    sec90dm character varying,
    sec90hf character varying,
    seccatdm character varying,
    seccathf character varying,
    secclrdm character varying,
    secclrhf character varying,
    soc2kdm character varying,
    soc2khf character varying,
    soc90dm character varying,
    soc90hf character varying,
    certtype integer,
    corareat character varying,
    corcertt character varying,
    doinqt character varying,
    dor character varying,
    inqcert integer,
    postmort integer,
    codfft_1 character varying,
    codfft_2 character varying,
    codfft_3 character varying,
    codfft_4 character varying,
    codfft_5 character varying,
    codfft_6 character varying,
    codfft_7 character varying,
    codfft_8 character varying,
    codfft_9 character varying,
    codfft_10 character varying,
    codfft_11 character varying,
    codfft_12 character varying,
    codfft_13 character varying,
    codfft_14 character varying,
    codfft_15 character varying,
    codfft_16 character varying,
    codfft_17 character varying,
    codfft_18 character varying,
    codfft_19 character varying,
    codfft_20 character varying,
    codfft_21 character varying,
    codfft_22 character varying,
    codfft_23 character varying,
    codfft_24 character varying,
    codfft_25 character varying,
    codfft_26 character varying,
    codfft_27 character varying,
    codfft_28 character varying,
    codfft_29 character varying,
    codfft_30 character varying,
    codfft_31 character varying,
    codfft_32 character varying,
    codfft_33 character varying,
    codfft_34 character varying,
    codfft_35 character varying,
    codfft_36 character varying,
    codfft_37 character varying,
    codfft_38 character varying,
    codfft_39 character varying,
    codfft_40 character varying,
    codfft_41 character varying,
    codfft_42 character varying,
    codfft_43 character varying,
    codfft_44 character varying,
    codfft_45 character varying,
    codfft_46 character varying,
    codfft_47 character varying,
    codfft_48 character varying,
    codfft_49 character varying,
    codfft_50 character varying,
    codfft_51 character varying,
    codfft_52 character varying,
    codfft_53 character varying,
    codfft_54 character varying,
    codfft_55 character varying,
    codfft_56 character varying,
    codfft_57 character varying,
    codfft_58 character varying,
    codfft_59 character varying,
    codfft_60 character varying,
    codfft_61 character varying,
    codfft_62 character varying,
    codfft_63 character varying,
    codfft_64 character varying,
    codfft_65 character varying,
    ccg9pod character varying,
    ccg9r character varying,
    gor9r character varying,
    ward9r character varying
);


--
-- Name: death_data_death_dataid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.death_data_death_dataid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: death_data_death_dataid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.death_data_death_dataid_seq OWNED BY public.death_data.death_dataid;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: directorates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directorates (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active boolean DEFAULT true
);


--
-- Name: directorates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.directorates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: directorates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.directorates_id_seq OWNED BY public.directorates.id;


--
-- Name: divisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.divisions (
    id integer NOT NULL,
    directorate_id integer,
    name character varying,
    head_of_profession character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active boolean DEFAULT true
);


--
-- Name: divisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.divisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: divisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.divisions_id_seq OWNED BY public.divisions.id;


--
-- Name: e_action; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.e_action (
    e_actionid bigint NOT NULL,
    e_batchid bigint,
    e_actiontype character varying(255),
    started timestamp without time zone,
    startedby character varying(255),
    finished timestamp without time zone,
    comments character varying(4000),
    status character varying(255),
    lock_version bigint DEFAULT 0 NOT NULL
);


--
-- Name: e_action_e_actionid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.e_action_e_actionid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: e_action_e_actionid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.e_action_e_actionid_seq OWNED BY public.e_action.e_actionid;


--
-- Name: e_batch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.e_batch (
    e_batchid bigint NOT NULL,
    e_type character varying(255),
    provider character varying(255),
    media character varying(255),
    original_filename character varying(255),
    cleaned_filename character varying(255),
    numberofrecords bigint,
    date_reference1 timestamp without time zone,
    date_reference2 timestamp without time zone,
    e_batchid_traced bigint,
    comments character varying(255),
    digest character varying(40),
    lock_version bigint DEFAULT 0 NOT NULL,
    inprogress character varying(50),
    registryid character varying(255),
    on_hold smallint
);


--
-- Name: e_batch_e_batchid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.e_batch_e_batchid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: e_batch_e_batchid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.e_batch_e_batchid_seq OWNED BY public.e_batch.e_batchid;


--
-- Name: e_workflow; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.e_workflow (
    e_workflowid bigint NOT NULL,
    e_type character varying(255),
    provider character varying(255),
    last_e_actiontype character varying(255),
    next_e_actiontype character varying(255),
    comments character varying(255),
    sort smallint
);


--
-- Name: e_workflow_e_workflowid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.e_workflow_e_workflowid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: e_workflow_e_workflowid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.e_workflow_e_workflowid_seq OWNED BY public.e_workflow.e_workflowid;


--
-- Name: end_uses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.end_uses (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: end_uses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.end_uses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: end_uses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.end_uses_id_seq OWNED BY public.end_uses.id;


--
-- Name: entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entities (
    id bigint NOT NULL,
    name character varying,
    title character varying,
    description character varying,
    parent_id integer,
    dataset_version_id integer,
    min_occurs integer,
    max_occurs integer,
    sort integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.entities_id_seq OWNED BY public.entities.id;


--
-- Name: enumeration_value_dataset_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enumeration_value_dataset_versions (
    id bigint NOT NULL,
    enumeration_value_id bigint,
    dataset_version_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: enumeration_value_dataset_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enumeration_value_dataset_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enumeration_value_dataset_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enumeration_value_dataset_versions_id_seq OWNED BY public.enumeration_value_dataset_versions.id;


--
-- Name: enumeration_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enumeration_values (
    id bigint NOT NULL,
    enumeration_value character varying,
    annotation character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sort integer,
    xml_type_id integer
);


--
-- Name: enumeration_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enumeration_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enumeration_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enumeration_values_id_seq OWNED BY public.enumeration_values.id;


--
-- Name: era_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.era_fields (
    id bigint NOT NULL,
    node_id bigint,
    ebr character varying[],
    ebr_rawtext_name character varying,
    ebr_virtual_name character varying[],
    event character varying[],
    event_field_name character varying[],
    comments character varying(255),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lookup_table character varying
);


--
-- Name: era_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.era_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: era_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.era_fields_id_seq OWNED BY public.era_fields.id;


--
-- Name: error_fingerprints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.error_fingerprints (
    error_fingerprintid character varying NOT NULL,
    ticket_url character varying,
    status character varying,
    count integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    causal_error_fingerprintid character varying
);


--
-- Name: error_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.error_logs (
    error_logid character varying NOT NULL,
    error_fingerprintid character varying,
    error_class character varying,
    description text,
    user_roles character varying,
    lines text,
    parameters_yml text,
    url character varying,
    user_agent character varying,
    ip character varying,
    hostname character varying,
    database character varying,
    clock_drift double precision,
    svn_revision character varying,
    port integer,
    process_id integer,
    status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer
);


--
-- Name: genetic_sequence_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genetic_sequence_variants (
    geneticsequencevariantid integer NOT NULL,
    genetic_test_result_id integer,
    humangenomebuild numeric(19,0),
    referencetranscriptid text,
    genomicchange text,
    codingdnasequencechange text,
    proteinimpact text,
    clinvarid text,
    cosmicid text,
    variantpathclass numeric(19,0),
    variantlocation numeric(19,0),
    exonintroncodonnumber text,
    sequencevarianttype numeric(19,0),
    variantimpact numeric(19,0),
    variantgenotype numeric(19,0),
    variantallelefrequency double precision,
    variantreport text,
    raw_record text,
    age integer
);


--
-- Name: genetic_sequence_variants_geneticsequencevariantid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genetic_sequence_variants_geneticsequencevariantid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genetic_sequence_variants_geneticsequencevariantid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genetic_sequence_variants_geneticsequencevariantid_seq OWNED BY public.genetic_sequence_variants.geneticsequencevariantid;


--
-- Name: genetic_test_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genetic_test_results (
    genetictestresultid integer NOT NULL,
    molecular_data_id integer,
    teststatus numeric(19,0),
    geneticaberrationtype numeric(19,0),
    karyotypearrayresult text,
    rapidniptresult numeric(19,0),
    gene text,
    genotype text,
    zygosity numeric(19,0),
    chromosomenumber numeric(19,0),
    chromosomearm numeric(19,0),
    cytogeneticband text,
    fusionpartnergene text,
    fusionpartnerchromosomenumber numeric(19,0),
    fusionpartnerchromosomearm numeric(19,0),
    fusionpartnercytogeneticband text,
    msistatus numeric(19,0),
    report text,
    geneticinheritance numeric(19,0),
    percentmutantalabkaryotype text,
    oncotypedxbreastrecurscore numeric(19,0),
    raw_record text,
    age integer
);


--
-- Name: genetic_test_results_genetictestresultid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genetic_test_results_genetictestresultid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genetic_test_results_genetictestresultid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genetic_test_results_genetictestresultid_seq OWNED BY public.genetic_test_results.genetictestresultid;


--
-- Name: governances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.governances (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: governances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.governances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: governances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.governances_id_seq OWNED BY public.governances.id;


--
-- Name: grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grants (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    roleable_type character varying,
    roleable_id bigint,
    team_id integer,
    project_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    dataset_id integer
);


--
-- Name: grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grants_id_seq OWNED BY public.grants.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name character varying,
    shortdesc character varying,
    description character varying,
    dataset_version_id integer,
    sort integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: identifiability_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identifiability_levels (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: identifiability_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.identifiability_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identifiability_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.identifiability_levels_id_seq OWNED BY public.identifiability_levels.id;


--
-- Name: ig_assessment_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ig_assessment_statuses (
    id bigint NOT NULL,
    value character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ig_assessment_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ig_assessment_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ig_assessment_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ig_assessment_statuses_id_seq OWNED BY public.ig_assessment_statuses.id;


--
-- Name: lawful_bases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lawful_bases (
    id character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: legal_gateways; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legal_gateways (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: legal_gateways_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legal_gateways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legal_gateways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legal_gateways_id_seq OWNED BY public.legal_gateways.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memberships (
    id integer NOT NULL,
    team_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    senior boolean
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memberships_id_seq OWNED BY public.memberships.id;


--
-- Name: molecular_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.molecular_data (
    molecular_dataid bigint NOT NULL,
    ppatient_id bigint,
    providercode text,
    practitionercode text,
    patienttype text,
    requesteddate date,
    collecteddate date,
    receiveddate date,
    authoriseddate date,
    indicationcategory integer,
    clinicalindication text,
    moleculartestingtype integer,
    organisationcode_testresult text,
    servicereportidentifier text,
    specimentype integer,
    otherspecimentype text,
    tumourpercentage text,
    specimenprep integer,
    karyotypingmethod integer,
    genetictestscope text,
    isresearchtest text,
    genetictestresults jsonb,
    sourcetype text,
    comments text,
    datefirstnotified date,
    raw_record text,
    age integer
);


--
-- Name: molecular_data_molecular_dataid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.molecular_data_molecular_dataid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: molecular_data_molecular_dataid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.molecular_data_molecular_dataid_seq OWNED BY public.molecular_data.molecular_dataid;


--
-- Name: namespaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespaces (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: namespaces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.namespaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: namespaces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.namespaces_id_seq OWNED BY public.namespaces.id;


--
-- Name: node_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.node_categories (
    id bigint NOT NULL,
    node_id bigint,
    category_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: node_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.node_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: node_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.node_categories_id_seq OWNED BY public.node_categories.id;


--
-- Name: node_version_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.node_version_mappings (
    id bigint NOT NULL,
    node_id integer,
    previous_node_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: node_version_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.node_version_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: node_version_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.node_version_mappings_id_seq OWNED BY public.node_version_mappings.id;


--
-- Name: nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nodes (
    id bigint NOT NULL,
    dataset_version_id integer,
    type character varying,
    parent_id integer,
    name character varying,
    reference character varying,
    annotation character varying,
    description character varying,
    xml_type_id integer,
    data_dictionary_element_id integer,
    choice_type_id integer,
    sort integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    category_id integer,
    min_occurs integer,
    max_occurs integer,
    governance_id integer,
    derived boolean,
    description_detail text,
    table_id integer,
    table_name character varying,
    table_schema_name character varying,
    qualified_table_name character varying,
    table_type character varying,
    table_type_description text,
    number_of_columns integer,
    primary_key_name character varying,
    primary_key_columns character varying,
    table_description text,
    table_comment character varying,
    published boolean,
    removed boolean,
    column_id integer,
    field_number integer,
    field_name character varying,
    field_type character varying,
    allow_nulls boolean,
    hes_field_name character varying,
    field_description text,
    validation_rules text,
    restrictions_recommendations text,
    notes text
);


--
-- Name: nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nodes_id_seq OWNED BY public.nodes.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    title character varying,
    body character varying,
    created_by character varying,
    notification_template_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    admin_users boolean,
    odr_users boolean,
    senior_users boolean,
    user_id integer,
    project_id integer,
    team_id integer,
    all_users boolean
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: organisation_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organisation_types (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: organisation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organisation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organisation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organisation_types_id_seq OWNED BY public.organisation_types.id;


--
-- Name: organisations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organisations (
    id bigint NOT NULL,
    name character varying,
    add1 character varying,
    add2 character varying,
    city character varying,
    postcode character varying,
    country_id character varying,
    organisation_type_id bigint,
    organisation_type_other character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: organisations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organisations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organisations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organisations_id_seq OWNED BY public.organisations.id;


--
-- Name: outputs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outputs (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: outputs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outputs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outputs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outputs_id_seq OWNED BY public.outputs.id;


--
-- Name: ppatient_rawdata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ppatient_rawdata (
    ppatient_rawdataid bigint NOT NULL,
    rawdata bytea,
    decrypt_key bytea
);


--
-- Name: ppatient_rawdata_ppatient_rawdataid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ppatient_rawdata_ppatient_rawdataid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ppatient_rawdata_ppatient_rawdataid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ppatient_rawdata_ppatient_rawdataid_seq OWNED BY public.ppatient_rawdata.ppatient_rawdataid;


--
-- Name: ppatients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ppatients (
    id bigint NOT NULL,
    e_batch_id integer,
    ppatient_rawdata_id bigint,
    type character varying,
    pseudo_id1 text,
    pseudo_id2 text,
    pseudonymisation_keyid integer
);


--
-- Name: ppatients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ppatients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ppatients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ppatients_id_seq OWNED BY public.ppatients.id;


--
-- Name: prescription_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prescription_data (
    prescription_dataid bigint NOT NULL,
    ppatient_id bigint,
    part_month text,
    presc_date date,
    presc_postcode text,
    pco_code text,
    pco_name text,
    practice_code text,
    practice_name text,
    nic text,
    presc_quantity text,
    item_number integer,
    unit_of_measure text,
    pay_quantity integer,
    drug_paid text,
    bnf_code text,
    pat_age integer,
    pf_exempt_cat text,
    etp_exempt_cat text,
    etp_indicator text,
    pf_id bigint,
    ampp_id bigint,
    vmpp_id bigint,
    sex text,
    form_type text,
    chemical_substance_bnf text,
    chemical_substance_bnf_descr text,
    vmp_id bigint,
    vmp_name text,
    vtm_name text
);


--
-- Name: prescription_data_prescription_dataid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prescription_data_prescription_dataid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prescription_data_prescription_dataid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prescription_data_prescription_dataid_seq OWNED BY public.prescription_data.prescription_dataid;


--
-- Name: processing_territories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.processing_territories (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: processing_territories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.processing_territories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: processing_territories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.processing_territories_id_seq OWNED BY public.processing_territories.id;


--
-- Name: programme_supports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme_supports (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: programme_supports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programme_supports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: programme_supports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programme_supports_id_seq OWNED BY public.programme_supports.id;


--
-- Name: project_amendments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_amendments (
    id bigint NOT NULL,
    project_id bigint,
    requested_at timestamp without time zone NOT NULL,
    labels character varying[] DEFAULT '{}'::character varying[],
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    project_state_id bigint,
    reference character varying,
    amendment_approved_date date
);


--
-- Name: project_amendments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_amendments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_amendments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_amendments_id_seq OWNED BY public.project_amendments.id;


--
-- Name: project_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_attachments (
    id integer NOT NULL,
    project_id integer,
    name character varying,
    comments character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    attachment_file_name character varying,
    attachment_content_type character varying,
    attachment_file_size integer,
    attachment_updated_at timestamp without time zone,
    attachment_contents bytea,
    digest character varying,
    workflow_project_state_id bigint,
    attachable_type character varying,
    attachable_id bigint
);


--
-- Name: project_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_attachments_id_seq OWNED BY public.project_attachments.id;


--
-- Name: project_classifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_classifications (
    id integer NOT NULL,
    project_id integer,
    classification_id integer
);


--
-- Name: project_classifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_classifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_classifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_classifications_id_seq OWNED BY public.project_classifications.id;


--
-- Name: project_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_comments (
    id integer NOT NULL,
    project_id integer,
    user_id integer,
    user_role character varying,
    comment_type character varying,
    comment text,
    project_data_source_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    project_node_id integer
);


--
-- Name: project_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_comments_id_seq OWNED BY public.project_comments.id;


--
-- Name: project_data_end_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_data_end_users (
    id integer NOT NULL,
    project_id integer,
    first_name character varying,
    last_name character varying,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ts_cs_accepted boolean
);


--
-- Name: project_data_end_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_data_end_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_data_end_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_data_end_users_id_seq OWNED BY public.project_data_end_users.id;


--
-- Name: project_data_passwords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_data_passwords (
    id integer NOT NULL,
    project_id integer,
    rawdata bytea,
    expired timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_data_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_data_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_data_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_data_passwords_id_seq OWNED BY public.project_data_passwords.id;


--
-- Name: project_data_source_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_data_source_items (
    id integer NOT NULL,
    project_id integer,
    data_source_item_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    approved boolean
);


--
-- Name: project_data_source_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_data_source_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_data_source_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_data_source_items_id_seq OWNED BY public.project_data_source_items.id;


--
-- Name: project_dataset_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_dataset_levels (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    project_dataset_id bigint,
    access_level_id integer,
    expiry_date date,
    selected boolean,
    decided_at timestamp without time zone,
    status integer
);


--
-- Name: project_dataset_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_dataset_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_dataset_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_dataset_levels_id_seq OWNED BY public.project_dataset_levels.id;


--
-- Name: project_datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_datasets (
    id bigint NOT NULL,
    project_id bigint,
    dataset_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    terms_accepted boolean
);


--
-- Name: project_datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_datasets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_datasets_id_seq OWNED BY public.project_datasets.id;


--
-- Name: project_relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_relationships (
    id bigint NOT NULL,
    left_project_id bigint NOT NULL,
    right_project_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT chk_rails_b7cab0758f CHECK ((left_project_id <> right_project_id))
);


--
-- Name: project_edges; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.project_edges AS
 SELECT project_relationships.id AS project_relationship_id,
    project_relationships.left_project_id AS project_id,
    project_relationships.right_project_id AS related_project_id,
    project_relationships.created_at,
    project_relationships.updated_at
   FROM public.project_relationships
UNION
 SELECT project_relationships.id AS project_relationship_id,
    project_relationships.right_project_id AS project_id,
    project_relationships.left_project_id AS related_project_id,
    project_relationships.created_at,
    project_relationships.updated_at
   FROM public.project_relationships;


--
-- Name: project_end_uses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_end_uses (
    id integer NOT NULL,
    project_id integer,
    end_use_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_end_uses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_end_uses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_end_uses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_end_uses_id_seq OWNED BY public.project_end_uses.id;


--
-- Name: project_lawful_bases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_lawful_bases (
    id bigint NOT NULL,
    project_id bigint,
    lawful_basis_id character varying
);


--
-- Name: project_lawful_bases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_lawful_bases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_lawful_bases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_lawful_bases_id_seq OWNED BY public.project_lawful_bases.id;


--
-- Name: project_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_memberships (
    id integer NOT NULL,
    project_id integer NOT NULL,
    membership_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    senior boolean
);


--
-- Name: project_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_memberships_id_seq OWNED BY public.project_memberships.id;


--
-- Name: project_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_nodes (
    id bigint NOT NULL,
    project_id bigint,
    node_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    approved boolean
);


--
-- Name: project_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_nodes_id_seq OWNED BY public.project_nodes.id;


--
-- Name: project_outputs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_outputs (
    id integer NOT NULL,
    project_id integer,
    output_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_outputs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_outputs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_outputs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_outputs_id_seq OWNED BY public.project_outputs.id;


--
-- Name: project_purposes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_purposes (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_purposes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_purposes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_purposes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_purposes_id_seq OWNED BY public.project_purposes.id;


--
-- Name: project_relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_relationships_id_seq OWNED BY public.project_relationships.id;


--
-- Name: project_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_roles (
    id bigint NOT NULL,
    name character varying,
    startdate timestamp without time zone,
    enddate timestamp without time zone,
    sort integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: project_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_roles_id_seq OWNED BY public.project_roles.id;


--
-- Name: project_type_datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_type_datasets (
    id bigint NOT NULL,
    project_type_id bigint,
    dataset_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: project_type_datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_type_datasets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_type_datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_type_datasets_id_seq OWNED BY public.project_type_datasets.id;


--
-- Name: project_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_types (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_types_id_seq OWNED BY public.project_types.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    name character varying,
    description text,
    z_project_status_id integer,
    start_data_date date,
    end_data_date date,
    team_id integer,
    how_data_will_be_used text,
    head_of_profession character varying,
    senior_user_id integer,
    data_access_address character varying,
    data_access_postcode character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    team_data_source_id integer,
    details_approved boolean,
    members_approved boolean,
    end_use_other character varying,
    data_to_contact_others boolean,
    data_to_contact_others_desc text,
    data_already_held_for_project boolean,
    data_linkage text,
    frequency character varying,
    frequency_other character varying,
    acg_support boolean,
    acg_who character varying,
    acg_date date,
    outputs_other character varying,
    cohort_inclusion_exclusion_criteria text,
    informed_patient_consent boolean,
    ethics_approval_obtained boolean,
    ethics_approval_nrec_name character varying,
    ethics_approval_nrec_ref character varying,
    legal_ethical_approved boolean,
    legal_ethical_approval_comments text,
    delegate_approved boolean,
    direct_care boolean,
    section_251_exempt boolean,
    cag_ref character varying,
    date_of_approval date,
    date_of_renewal date,
    regulation_health_services boolean,
    caldicott_email character varying,
    informed_patient_consent_mortality boolean,
    s42_of_srsa boolean,
    approved_research_accreditation boolean,
    trackwise_id character varying,
    clone_of integer,
    main_contact_name character varying,
    main_contact_email character varying,
    awarding_body_ref character varying,
    application_log character varying,
    application_data_sharing_reference character varying,
    crpd_reference character varying,
    project_purpose text,
    project_summary text,
    why_data_required text,
    public_benefit text,
    duration integer,
    data_asset_required text,
    onwardly_share boolean DEFAULT false,
    onwardly_share_detail text,
    data_already_held_detail text,
    programme_support_detail text,
    scrn_id character varying,
    programme_approval_date timestamp without time zone,
    phe_contacts text,
    s251_exemption_id integer,
    legal_gateway_id integer,
    rec_committee_id integer,
    rec_reference character varying,
    applicant_certification boolean,
    outsourced_certification boolean,
    additional_info text,
    application_date timestamp without time zone,
    first_contact_date timestamp without time zone,
    first_reply_date timestamp without time zone,
    release_date timestamp without time zone,
    ndg_opt_out_applied boolean DEFAULT false,
    ndg_opt_out_processed_date timestamp without time zone,
    destruction_form_received_date timestamp without time zone,
    assigned_user_id integer,
    organisation_name character varying,
    organisation_department character varying,
    organisation_add1 character varying,
    organisation_add2 character varying,
    organisation_city character varying,
    organisation_postcode character varying,
    organisation_country_id character varying,
    organisation_type_id integer,
    organisation_type_other character varying,
    sponsor_name character varying,
    sponsor_add1 character varying,
    sponsor_add2 character varying,
    sponsor_city character varying,
    sponsor_postcode character varying,
    sponsor_country_id character varying,
    funder_name character varying,
    funder_add1 character varying,
    funder_add2 character varying,
    funder_city character varying,
    funder_postcode character varying,
    funder_country_id character varying,
    data_processor_name character varying,
    data_processor_add1 character varying,
    data_processor_add2 character varying,
    data_processor_city character varying,
    data_processor_postcode character varying,
    data_processor_country_id character varying,
    processing_territory_id integer,
    processing_territory_other character varying,
    dpa_org_code character varying,
    dpa_org_name character varying,
    dpa_registration_end_date timestamp without time zone,
    security_assurance_id integer,
    ig_code character varying,
    ig_score integer,
    ig_toolkit_version character varying,
    processing_territory_outsourced_other character varying,
    dpa_org_code_outsourced character varying,
    dpa_org_name_outsourced character varying,
    dpa_registration_end_date_outsourced timestamp without time zone,
    security_assurance_outsourced_id integer,
    ig_code_outsourced character varying,
    ig_score_outsourced integer,
    ig_toolkit_version_outsourced character varying,
    applicant_title_id integer,
    applicant_first_name character varying,
    applicant_last_name character varying,
    applicant_job_title character varying,
    applicant_email character varying,
    applicant_telephone character varying,
    applicant_title character varying,
    organisation_country character varying,
    organisation_type character varying,
    data_end_use character varying,
    level_of_identifiability character varying,
    s251_exemption character varying,
    article6 character varying,
    article9 character varying,
    processing_territory character varying,
    security_assurance_provided character varying,
    assigned_to character varying,
    amendment_type character varying,
    spectrum_of_identifiability character varying,
    project_type_id integer DEFAULT 1,
    team_dataset_id integer,
    closure_reason_id bigint,
    rec_name character varying,
    processing_territory_outsourced_id integer,
    form_data jsonb DEFAULT '{}'::jsonb,
    dataset_id integer,
    receiptsentby character varying,
    closure_date date,
    programme_support_id integer,
    amendment_number integer DEFAULT 0
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: propositions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.propositions (
    id character varying(2) NOT NULL,
    value character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pseudonymisation_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pseudonymisation_keys (
    pseudonymisation_keyid integer NOT NULL,
    key_name text,
    startdate date,
    enddate date,
    comments text,
    e_type character varying(255),
    provider character varying(255)
);


--
-- Name: pseudonymisation_keys_pseudonymisation_keyid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pseudonymisation_keys_pseudonymisation_keyid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pseudonymisation_keys_pseudonymisation_keyid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pseudonymisation_keys_pseudonymisation_keyid_seq OWNED BY public.pseudonymisation_keys.pseudonymisation_keyid;


--
-- Name: rec_committees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rec_committees (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: rec_committees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rec_committees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rec_committees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rec_committees_id_seq OWNED BY public.rec_committees.id;


--
-- Name: releases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.releases (
    id bigint NOT NULL,
    project_id bigint,
    project_state_id bigint,
    invoice_requested_date timestamp without time zone,
    invoice_sent_date timestamp without time zone,
    phe_invoice_number character varying,
    po_number character varying,
    ndg_opt_out_processed_date timestamp without time zone,
    cprd_reference character varying,
    actual_cost numeric(10,2),
    vat_reg character varying(2),
    income_received character varying(2),
    cost_recovery_applied character varying(2),
    drr_no character varying,
    individual_to_release character varying,
    release_date timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    reference character varying,
    referent_type character varying NOT NULL,
    referent_id bigint NOT NULL,
    referent_reference character varying
);


--
-- Name: releases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.releases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: releases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.releases_id_seq OWNED BY public.releases.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: security_assurances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security_assurances (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: security_assurances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.security_assurances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: security_assurances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.security_assurances_id_seq OWNED BY public.security_assurances.id;


--
-- Name: system_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_roles (
    id bigint NOT NULL,
    name character varying,
    startdate timestamp without time zone,
    enddate timestamp without time zone,
    sort integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: system_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_roles_id_seq OWNED BY public.system_roles.id;


--
-- Name: team_data_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_data_sources (
    id integer NOT NULL,
    team_id integer,
    data_source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: team_data_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_data_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_data_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_data_sources_id_seq OWNED BY public.team_data_sources.id;


--
-- Name: team_datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_datasets (
    id bigint NOT NULL,
    team_id integer,
    dataset_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: team_datasets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_datasets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_datasets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_datasets_id_seq OWNED BY public.team_datasets.id;


--
-- Name: team_delegate_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_delegate_users (
    id integer NOT NULL,
    team_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: team_delegate_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_delegate_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_delegate_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_delegate_users_id_seq OWNED BY public.team_delegate_users.id;


--
-- Name: team_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_roles (
    id bigint NOT NULL,
    name character varying,
    role_type character varying,
    startdate timestamp without time zone,
    enddate timestamp without time zone,
    sort integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: team_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_roles_id_seq OWNED BY public.team_roles.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    name character varying,
    location character varying,
    postcode character varying,
    z_team_status_id integer,
    telephone character varying,
    notes character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    division_id integer,
    directorate_id integer,
    delegate_approver integer,
    organisation_id bigint
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: titles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.titles (
    id bigint NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: titles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.titles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: titles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.titles_id_seq OWNED BY public.titles.id;


--
-- Name: user_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_notifications (
    id integer NOT NULL,
    user_id integer,
    notification_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status character varying DEFAULT 'new'::character varying NOT NULL
);


--
-- Name: user_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_notifications_id_seq OWNED BY public.user_notifications.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    failed_attempts integer DEFAULT 0 NOT NULL,
    locked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    first_name character varying,
    last_name character varying,
    telephone character varying,
    mobile character varying,
    location character varying,
    notes text,
    z_user_status_id integer,
    job_title character varying,
    username character varying,
    rejected_terms_count integer DEFAULT 0,
    grade character varying,
    employment character varying,
    contract_end_date date,
    directorate_id integer,
    division_id integer,
    delegate_user boolean,
    title_id bigint,
    upn character varying,
    object_guid character varying,
    session_index character varying,
    line_manager_name character varying,
    line_manager_email character varying,
    line_manager_telephone character varying,
    contract_start_date date
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: version_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.version_associations (
    id integer NOT NULL,
    version_id integer,
    foreign_key_name character varying NOT NULL,
    foreign_key_id integer,
    foreign_type character varying
);


--
-- Name: version_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.version_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: version_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.version_associations_id_seq OWNED BY public.version_associations.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp without time zone,
    object_changes text,
    transaction_id integer
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: workflow_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_assignments (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    project_state_id bigint NOT NULL,
    assigned_user_id bigint NOT NULL,
    assigning_user_id bigint
);


--
-- Name: workflow_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_assignments_id_seq OWNED BY public.workflow_assignments.id;


--
-- Name: workflow_project_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_project_states (
    id bigint NOT NULL,
    state_id character varying NOT NULL,
    project_id integer NOT NULL,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: workflow_current_project_states; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.workflow_current_project_states AS
 SELECT t.id,
    t.project_id,
    p.state_id,
    p.user_id,
    u.assigned_user_id,
    u.assigning_user_id,
    p.created_at,
    p.updated_at
   FROM ((( SELECT workflow_project_states.project_id,
            max(workflow_project_states.id) AS id
           FROM public.workflow_project_states
          GROUP BY workflow_project_states.project_id) t
     LEFT JOIN public.workflow_project_states p ON ((p.id = t.id)))
     LEFT JOIN LATERAL ( SELECT workflow_assignments.assigned_user_id,
            workflow_assignments.assigning_user_id
           FROM public.workflow_assignments
          WHERE (workflow_assignments.project_state_id = t.id)
          ORDER BY workflow_assignments.id DESC
         LIMIT 1) u ON (true));


--
-- Name: workflow_project_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_project_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_project_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_project_states_id_seq OWNED BY public.workflow_project_states.id;


--
-- Name: workflow_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_states (
    id character varying NOT NULL,
    description character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: workflow_transitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_transitions (
    id bigint NOT NULL,
    project_type_id integer,
    from_state_id character varying NOT NULL,
    next_state_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    requires_yubikey boolean DEFAULT false
);


--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_transitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_transitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_transitions_id_seq OWNED BY public.workflow_transitions.id;


--
-- Name: xml_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xml_attributes (
    id bigint NOT NULL,
    "default" character varying,
    fixed character varying,
    form character varying,
    attribute_id character varying,
    name character varying,
    ref character varying,
    type character varying,
    use character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: xml_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.xml_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: xml_attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.xml_attributes_id_seq OWNED BY public.xml_attributes.id;


--
-- Name: xml_type_xml_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xml_type_xml_attributes (
    id bigint NOT NULL,
    xml_type_id bigint,
    xml_attribute_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: xml_type_xml_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.xml_type_xml_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: xml_type_xml_attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.xml_type_xml_attributes_id_seq OWNED BY public.xml_type_xml_attributes.id;


--
-- Name: xml_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xml_types (
    id bigint NOT NULL,
    name character varying,
    annotation character varying,
    min_length numeric,
    max_length numeric,
    pattern character varying,
    restriction character varying,
    namespace_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    fractiondigits integer,
    totaldigits integer,
    xml_attribute_for_value_id integer
);


--
-- Name: xml_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.xml_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: xml_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.xml_types_id_seq OWNED BY public.xml_types.id;


--
-- Name: z_project_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.z_project_statuses (
    id integer NOT NULL,
    name character varying,
    description character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: z_project_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.z_project_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: z_project_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.z_project_statuses_id_seq OWNED BY public.z_project_statuses.id;


--
-- Name: z_team_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.z_team_statuses (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: z_team_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.z_team_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: z_team_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.z_team_statuses_id_seq OWNED BY public.z_team_statuses.id;


--
-- Name: z_user_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.z_user_statuses (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: z_user_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.z_user_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: z_user_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.z_user_statuses_id_seq OWNED BY public.z_user_statuses.id;


--
-- Name: ze_actiontype; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ze_actiontype (
    ze_actiontypeid character varying(255) DEFAULT '1'::character varying NOT NULL,
    shortdesc character varying(64),
    description character varying(255),
    startdate timestamp without time zone,
    enddate timestamp without time zone,
    sort bigint,
    comments character varying(255)
);


--
-- Name: ze_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ze_type (
    ze_typeid character varying(255) NOT NULL,
    shortdesc character varying(64),
    description character varying(255),
    startdate timestamp without time zone,
    enddate timestamp without time zone,
    sort bigint,
    comments character varying(255)
);


--
-- Name: zprovider; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zprovider (
    zproviderid character varying(255) DEFAULT '1'::character varying NOT NULL,
    shortdesc character varying(128),
    description character varying(2000),
    exportid character varying(64),
    startdate timestamp without time zone,
    enddate timestamp without time zone,
    sort bigint,
    role character varying(1),
    local_hospital smallint DEFAULT 0 NOT NULL,
    breast_screening_unit smallint DEFAULT 0 NOT NULL,
    historical smallint DEFAULT 0 NOT NULL,
    lpi_providercode character varying(255),
    zpostcodeid character varying(255),
    linac smallint DEFAULT 0 NOT NULL,
    analysisid character varying(255),
    nacscode smallint,
    nacs5id character varying(5),
    successorid character varying(255),
    local_registryid character varying(5),
    source character varying(255)
);


--
-- Name: zuser; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zuser (
    zuserid character varying(255) DEFAULT '1'::character varying NOT NULL,
    shortdesc character varying(64),
    description character varying(2000),
    exportid character varying(64),
    startdate timestamp without time zone,
    enddate timestamp without time zone,
    sort bigint,
    registryid character varying(5),
    qa_supervisorid character varying(255)
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_levels ALTER COLUMN id SET DEFAULT nextval('public.access_levels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.advisory_committees ALTER COLUMN id SET DEFAULT nextval('public.advisory_committees_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.amendment_types ALTER COLUMN id SET DEFAULT nextval('public.amendment_types_id_seq'::regclass);


--
-- Name: birth_dataid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.birth_data ALTER COLUMN birth_dataid SET DEFAULT nextval('public.birth_data_birth_dataid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_application_fields ALTER COLUMN id SET DEFAULT nextval('public.cas_application_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_declarations ALTER COLUMN id SET DEFAULT nextval('public.cas_declarations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.choice_types ALTER COLUMN id SET DEFAULT nextval('public.choice_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classifications ALTER COLUMN id SET DEFAULT nextval('public.classifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closure_reasons ALTER COLUMN id SET DEFAULT nextval('public.closure_reasons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.common_law_exemptions ALTER COLUMN id SET DEFAULT nextval('public.common_law_exemptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communications ALTER COLUMN id SET DEFAULT nextval('public.communications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract_types ALTER COLUMN id SET DEFAULT nextval('public.contract_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts ALTER COLUMN id SET DEFAULT nextval('public.contracts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cost_recoveries ALTER COLUMN id SET DEFAULT nextval('public.cost_recoveries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_dictionary_elements ALTER COLUMN id SET DEFAULT nextval('public.data_dictionary_elements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_item_groups ALTER COLUMN id SET DEFAULT nextval('public.data_item_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_items ALTER COLUMN id SET DEFAULT nextval('public.data_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_privacy_impact_assessments ALTER COLUMN id SET DEFAULT nextval('public.data_privacy_impact_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_source_items ALTER COLUMN id SET DEFAULT nextval('public.data_source_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources ALTER COLUMN id SET DEFAULT nextval('public.data_sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_roles ALTER COLUMN id SET DEFAULT nextval('public.dataset_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_types ALTER COLUMN id SET DEFAULT nextval('public.dataset_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_versions ALTER COLUMN id SET DEFAULT nextval('public.dataset_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets ALTER COLUMN id SET DEFAULT nextval('public.datasets_id_seq'::regclass);


--
-- Name: death_dataid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.death_data ALTER COLUMN death_dataid SET DEFAULT nextval('public.death_data_death_dataid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directorates ALTER COLUMN id SET DEFAULT nextval('public.directorates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.divisions ALTER COLUMN id SET DEFAULT nextval('public.divisions_id_seq'::regclass);


--
-- Name: e_actionid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_action ALTER COLUMN e_actionid SET DEFAULT nextval('public.e_action_e_actionid_seq'::regclass);


--
-- Name: e_batchid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_batch ALTER COLUMN e_batchid SET DEFAULT nextval('public.e_batch_e_batchid_seq'::regclass);


--
-- Name: e_workflowid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_workflow ALTER COLUMN e_workflowid SET DEFAULT nextval('public.e_workflow_e_workflowid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.end_uses ALTER COLUMN id SET DEFAULT nextval('public.end_uses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entities ALTER COLUMN id SET DEFAULT nextval('public.entities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enumeration_value_dataset_versions ALTER COLUMN id SET DEFAULT nextval('public.enumeration_value_dataset_versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enumeration_values ALTER COLUMN id SET DEFAULT nextval('public.enumeration_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.era_fields ALTER COLUMN id SET DEFAULT nextval('public.era_fields_id_seq'::regclass);


--
-- Name: geneticsequencevariantid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genetic_sequence_variants ALTER COLUMN geneticsequencevariantid SET DEFAULT nextval('public.genetic_sequence_variants_geneticsequencevariantid_seq'::regclass);


--
-- Name: genetictestresultid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genetic_test_results ALTER COLUMN genetictestresultid SET DEFAULT nextval('public.genetic_test_results_genetictestresultid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.governances ALTER COLUMN id SET DEFAULT nextval('public.governances_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grants ALTER COLUMN id SET DEFAULT nextval('public.grants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identifiability_levels ALTER COLUMN id SET DEFAULT nextval('public.identifiability_levels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ig_assessment_statuses ALTER COLUMN id SET DEFAULT nextval('public.ig_assessment_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_gateways ALTER COLUMN id SET DEFAULT nextval('public.legal_gateways_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships ALTER COLUMN id SET DEFAULT nextval('public.memberships_id_seq'::regclass);


--
-- Name: molecular_dataid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.molecular_data ALTER COLUMN molecular_dataid SET DEFAULT nextval('public.molecular_data_molecular_dataid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespaces ALTER COLUMN id SET DEFAULT nextval('public.namespaces_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_categories ALTER COLUMN id SET DEFAULT nextval('public.node_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_version_mappings ALTER COLUMN id SET DEFAULT nextval('public.node_version_mappings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nodes ALTER COLUMN id SET DEFAULT nextval('public.nodes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisation_types ALTER COLUMN id SET DEFAULT nextval('public.organisation_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations ALTER COLUMN id SET DEFAULT nextval('public.organisations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outputs ALTER COLUMN id SET DEFAULT nextval('public.outputs_id_seq'::regclass);


--
-- Name: ppatient_rawdataid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppatient_rawdata ALTER COLUMN ppatient_rawdataid SET DEFAULT nextval('public.ppatient_rawdata_ppatient_rawdataid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppatients ALTER COLUMN id SET DEFAULT nextval('public.ppatients_id_seq'::regclass);


--
-- Name: prescription_dataid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription_data ALTER COLUMN prescription_dataid SET DEFAULT nextval('public.prescription_data_prescription_dataid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processing_territories ALTER COLUMN id SET DEFAULT nextval('public.processing_territories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_supports ALTER COLUMN id SET DEFAULT nextval('public.programme_supports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_amendments ALTER COLUMN id SET DEFAULT nextval('public.project_amendments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_attachments ALTER COLUMN id SET DEFAULT nextval('public.project_attachments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_classifications ALTER COLUMN id SET DEFAULT nextval('public.project_classifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_comments ALTER COLUMN id SET DEFAULT nextval('public.project_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_end_users ALTER COLUMN id SET DEFAULT nextval('public.project_data_end_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_passwords ALTER COLUMN id SET DEFAULT nextval('public.project_data_passwords_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_source_items ALTER COLUMN id SET DEFAULT nextval('public.project_data_source_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_dataset_levels ALTER COLUMN id SET DEFAULT nextval('public.project_dataset_levels_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_datasets ALTER COLUMN id SET DEFAULT nextval('public.project_datasets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_end_uses ALTER COLUMN id SET DEFAULT nextval('public.project_end_uses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_lawful_bases ALTER COLUMN id SET DEFAULT nextval('public.project_lawful_bases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_memberships ALTER COLUMN id SET DEFAULT nextval('public.project_memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_nodes ALTER COLUMN id SET DEFAULT nextval('public.project_nodes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_outputs ALTER COLUMN id SET DEFAULT nextval('public.project_outputs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_purposes ALTER COLUMN id SET DEFAULT nextval('public.project_purposes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_relationships ALTER COLUMN id SET DEFAULT nextval('public.project_relationships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_roles ALTER COLUMN id SET DEFAULT nextval('public.project_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_type_datasets ALTER COLUMN id SET DEFAULT nextval('public.project_type_datasets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_types ALTER COLUMN id SET DEFAULT nextval('public.project_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: pseudonymisation_keyid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonymisation_keys ALTER COLUMN pseudonymisation_keyid SET DEFAULT nextval('public.pseudonymisation_keys_pseudonymisation_keyid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rec_committees ALTER COLUMN id SET DEFAULT nextval('public.rec_committees_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases ALTER COLUMN id SET DEFAULT nextval('public.releases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_assurances ALTER COLUMN id SET DEFAULT nextval('public.security_assurances_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_roles ALTER COLUMN id SET DEFAULT nextval('public.system_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_data_sources ALTER COLUMN id SET DEFAULT nextval('public.team_data_sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_datasets ALTER COLUMN id SET DEFAULT nextval('public.team_datasets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_delegate_users ALTER COLUMN id SET DEFAULT nextval('public.team_delegate_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_roles ALTER COLUMN id SET DEFAULT nextval('public.team_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.titles ALTER COLUMN id SET DEFAULT nextval('public.titles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notifications ALTER COLUMN id SET DEFAULT nextval('public.user_notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.version_associations ALTER COLUMN id SET DEFAULT nextval('public.version_associations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments ALTER COLUMN id SET DEFAULT nextval('public.workflow_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_project_states ALTER COLUMN id SET DEFAULT nextval('public.workflow_project_states_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions ALTER COLUMN id SET DEFAULT nextval('public.workflow_transitions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xml_attributes ALTER COLUMN id SET DEFAULT nextval('public.xml_attributes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xml_type_xml_attributes ALTER COLUMN id SET DEFAULT nextval('public.xml_type_xml_attributes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xml_types ALTER COLUMN id SET DEFAULT nextval('public.xml_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.z_project_statuses ALTER COLUMN id SET DEFAULT nextval('public.z_project_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.z_team_statuses ALTER COLUMN id SET DEFAULT nextval('public.z_team_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.z_user_statuses ALTER COLUMN id SET DEFAULT nextval('public.z_user_statuses_id_seq'::regclass);


--
-- Name: access_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_levels
    ADD CONSTRAINT access_levels_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: advisory_committees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.advisory_committees
    ADD CONSTRAINT advisory_committees_pkey PRIMARY KEY (id);


--
-- Name: amendment_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.amendment_types
    ADD CONSTRAINT amendment_types_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: birth_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.birth_data
    ADD CONSTRAINT birth_data_pkey PRIMARY KEY (birth_dataid);


--
-- Name: cas_application_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_application_fields
    ADD CONSTRAINT cas_application_fields_pkey PRIMARY KEY (id);


--
-- Name: cas_declarations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_declarations
    ADD CONSTRAINT cas_declarations_pkey PRIMARY KEY (id);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: choice_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.choice_types
    ADD CONSTRAINT choice_types_pkey PRIMARY KEY (id);


--
-- Name: classifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classifications
    ADD CONSTRAINT classifications_pkey PRIMARY KEY (id);


--
-- Name: closure_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closure_reasons
    ADD CONSTRAINT closure_reasons_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: common_law_exemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.common_law_exemptions
    ADD CONSTRAINT common_law_exemptions_pkey PRIMARY KEY (id);


--
-- Name: communications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communications
    ADD CONSTRAINT communications_pkey PRIMARY KEY (id);


--
-- Name: contract_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract_types
    ADD CONSTRAINT contract_types_pkey PRIMARY KEY (id);


--
-- Name: contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: cost_recoveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cost_recoveries
    ADD CONSTRAINT cost_recoveries_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: data_dictionary_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_dictionary_elements
    ADD CONSTRAINT data_dictionary_elements_pkey PRIMARY KEY (id);


--
-- Name: data_item_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_item_groups
    ADD CONSTRAINT data_item_groups_pkey PRIMARY KEY (id);


--
-- Name: data_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_items
    ADD CONSTRAINT data_items_pkey PRIMARY KEY (id);


--
-- Name: data_privacy_impact_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_privacy_impact_assessments
    ADD CONSTRAINT data_privacy_impact_assessments_pkey PRIMARY KEY (id);


--
-- Name: data_source_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_source_items
    ADD CONSTRAINT data_source_items_pkey PRIMARY KEY (id);


--
-- Name: data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources
    ADD CONSTRAINT data_sources_pkey PRIMARY KEY (id);


--
-- Name: dataset_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_roles
    ADD CONSTRAINT dataset_roles_pkey PRIMARY KEY (id);


--
-- Name: dataset_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_types
    ADD CONSTRAINT dataset_types_pkey PRIMARY KEY (id);


--
-- Name: dataset_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dataset_versions
    ADD CONSTRAINT dataset_versions_pkey PRIMARY KEY (id);


--
-- Name: datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);


--
-- Name: death_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.death_data
    ADD CONSTRAINT death_data_pkey PRIMARY KEY (death_dataid);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: directorates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directorates
    ADD CONSTRAINT directorates_pkey PRIMARY KEY (id);


--
-- Name: divisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.divisions
    ADD CONSTRAINT divisions_pkey PRIMARY KEY (id);


--
-- Name: e_action_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_action
    ADD CONSTRAINT e_action_pkey PRIMARY KEY (e_actionid);


--
-- Name: e_batch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_batch
    ADD CONSTRAINT e_batch_pkey PRIMARY KEY (e_batchid);


--
-- Name: e_workflow_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_workflow
    ADD CONSTRAINT e_workflow_pkey PRIMARY KEY (e_workflowid);


--
-- Name: end_uses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.end_uses
    ADD CONSTRAINT end_uses_pkey PRIMARY KEY (id);


--
-- Name: entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- Name: enumeration_value_dataset_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enumeration_value_dataset_versions
    ADD CONSTRAINT enumeration_value_dataset_versions_pkey PRIMARY KEY (id);


--
-- Name: enumeration_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enumeration_values
    ADD CONSTRAINT enumeration_values_pkey PRIMARY KEY (id);


--
-- Name: era_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.era_fields
    ADD CONSTRAINT era_fields_pkey PRIMARY KEY (id);


--
-- Name: error_fingerprints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_fingerprints
    ADD CONSTRAINT error_fingerprints_pkey PRIMARY KEY (error_fingerprintid);


--
-- Name: error_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_logs
    ADD CONSTRAINT error_logs_pkey PRIMARY KEY (error_logid);


--
-- Name: genetic_sequence_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genetic_sequence_variants
    ADD CONSTRAINT genetic_sequence_variants_pkey PRIMARY KEY (geneticsequencevariantid);


--
-- Name: genetic_test_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genetic_test_results
    ADD CONSTRAINT genetic_test_results_pkey PRIMARY KEY (genetictestresultid);


--
-- Name: governances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.governances
    ADD CONSTRAINT governances_pkey PRIMARY KEY (id);


--
-- Name: grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grants
    ADD CONSTRAINT grants_pkey PRIMARY KEY (id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: identifiability_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identifiability_levels
    ADD CONSTRAINT identifiability_levels_pkey PRIMARY KEY (id);


--
-- Name: ig_assessment_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ig_assessment_statuses
    ADD CONSTRAINT ig_assessment_statuses_pkey PRIMARY KEY (id);


--
-- Name: lawful_bases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lawful_bases
    ADD CONSTRAINT lawful_bases_pkey PRIMARY KEY (id);


--
-- Name: legal_gateways_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legal_gateways
    ADD CONSTRAINT legal_gateways_pkey PRIMARY KEY (id);


--
-- Name: memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: molecular_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.molecular_data
    ADD CONSTRAINT molecular_data_pkey PRIMARY KEY (molecular_dataid);


--
-- Name: namespaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_pkey PRIMARY KEY (id);


--
-- Name: node_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_categories
    ADD CONSTRAINT node_categories_pkey PRIMARY KEY (id);


--
-- Name: node_version_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_version_mappings
    ADD CONSTRAINT node_version_mappings_pkey PRIMARY KEY (id);


--
-- Name: nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nodes
    ADD CONSTRAINT nodes_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: organisation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisation_types
    ADD CONSTRAINT organisation_types_pkey PRIMARY KEY (id);


--
-- Name: organisations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT organisations_pkey PRIMARY KEY (id);


--
-- Name: outputs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outputs
    ADD CONSTRAINT outputs_pkey PRIMARY KEY (id);


--
-- Name: ppatient_rawdata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppatient_rawdata
    ADD CONSTRAINT ppatient_rawdata_pkey PRIMARY KEY (ppatient_rawdataid);


--
-- Name: ppatients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppatients
    ADD CONSTRAINT ppatients_pkey PRIMARY KEY (id);


--
-- Name: prescription_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription_data
    ADD CONSTRAINT prescription_data_pkey PRIMARY KEY (prescription_dataid);


--
-- Name: processing_territories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processing_territories
    ADD CONSTRAINT processing_territories_pkey PRIMARY KEY (id);


--
-- Name: programme_supports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_supports
    ADD CONSTRAINT programme_supports_pkey PRIMARY KEY (id);


--
-- Name: project_amendments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_amendments
    ADD CONSTRAINT project_amendments_pkey PRIMARY KEY (id);


--
-- Name: project_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_attachments
    ADD CONSTRAINT project_attachments_pkey PRIMARY KEY (id);


--
-- Name: project_classifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_classifications
    ADD CONSTRAINT project_classifications_pkey PRIMARY KEY (id);


--
-- Name: project_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_comments
    ADD CONSTRAINT project_comments_pkey PRIMARY KEY (id);


--
-- Name: project_data_end_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_end_users
    ADD CONSTRAINT project_data_end_users_pkey PRIMARY KEY (id);


--
-- Name: project_data_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_passwords
    ADD CONSTRAINT project_data_passwords_pkey PRIMARY KEY (id);


--
-- Name: project_data_source_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_source_items
    ADD CONSTRAINT project_data_source_items_pkey PRIMARY KEY (id);


--
-- Name: project_dataset_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_dataset_levels
    ADD CONSTRAINT project_dataset_levels_pkey PRIMARY KEY (id);


--
-- Name: project_datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_datasets
    ADD CONSTRAINT project_datasets_pkey PRIMARY KEY (id);


--
-- Name: project_end_uses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_end_uses
    ADD CONSTRAINT project_end_uses_pkey PRIMARY KEY (id);


--
-- Name: project_lawful_bases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_lawful_bases
    ADD CONSTRAINT project_lawful_bases_pkey PRIMARY KEY (id);


--
-- Name: project_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_memberships
    ADD CONSTRAINT project_memberships_pkey PRIMARY KEY (id);


--
-- Name: project_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_nodes
    ADD CONSTRAINT project_nodes_pkey PRIMARY KEY (id);


--
-- Name: project_outputs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_outputs
    ADD CONSTRAINT project_outputs_pkey PRIMARY KEY (id);


--
-- Name: project_purposes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_purposes
    ADD CONSTRAINT project_purposes_pkey PRIMARY KEY (id);


--
-- Name: project_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_relationships
    ADD CONSTRAINT project_relationships_pkey PRIMARY KEY (id);


--
-- Name: project_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_roles
    ADD CONSTRAINT project_roles_pkey PRIMARY KEY (id);


--
-- Name: project_type_datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_type_datasets
    ADD CONSTRAINT project_type_datasets_pkey PRIMARY KEY (id);


--
-- Name: project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_types
    ADD CONSTRAINT project_types_pkey PRIMARY KEY (id);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: propositions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.propositions
    ADD CONSTRAINT propositions_pkey PRIMARY KEY (id);


--
-- Name: pseudonymisation_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonymisation_keys
    ADD CONSTRAINT pseudonymisation_keys_pkey PRIMARY KEY (pseudonymisation_keyid);


--
-- Name: rec_committees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rec_committees
    ADD CONSTRAINT rec_committees_pkey PRIMARY KEY (id);


--
-- Name: releases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT releases_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: security_assurances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_assurances
    ADD CONSTRAINT security_assurances_pkey PRIMARY KEY (id);


--
-- Name: system_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_roles
    ADD CONSTRAINT system_roles_pkey PRIMARY KEY (id);


--
-- Name: team_data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_data_sources
    ADD CONSTRAINT team_data_sources_pkey PRIMARY KEY (id);


--
-- Name: team_datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_datasets
    ADD CONSTRAINT team_datasets_pkey PRIMARY KEY (id);


--
-- Name: team_delegate_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_delegate_users
    ADD CONSTRAINT team_delegate_users_pkey PRIMARY KEY (id);


--
-- Name: team_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_roles
    ADD CONSTRAINT team_roles_pkey PRIMARY KEY (id);


--
-- Name: teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: titles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.titles
    ADD CONSTRAINT titles_pkey PRIMARY KEY (id);


--
-- Name: user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: version_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.version_associations
    ADD CONSTRAINT version_associations_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: workflow_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT workflow_assignments_pkey PRIMARY KEY (id);


--
-- Name: workflow_project_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_project_states
    ADD CONSTRAINT workflow_project_states_pkey PRIMARY KEY (id);


--
-- Name: workflow_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_states
    ADD CONSTRAINT workflow_states_pkey PRIMARY KEY (id);


--
-- Name: workflow_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT workflow_transitions_pkey PRIMARY KEY (id);


--
-- Name: xml_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xml_attributes
    ADD CONSTRAINT xml_attributes_pkey PRIMARY KEY (id);


--
-- Name: xml_type_xml_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xml_type_xml_attributes
    ADD CONSTRAINT xml_type_xml_attributes_pkey PRIMARY KEY (id);


--
-- Name: xml_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xml_types
    ADD CONSTRAINT xml_types_pkey PRIMARY KEY (id);


--
-- Name: z_project_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.z_project_statuses
    ADD CONSTRAINT z_project_statuses_pkey PRIMARY KEY (id);


--
-- Name: z_team_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.z_team_statuses
    ADD CONSTRAINT z_team_statuses_pkey PRIMARY KEY (id);


--
-- Name: z_user_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.z_user_statuses
    ADD CONSTRAINT z_user_statuses_pkey PRIMARY KEY (id);


--
-- Name: ze_actiontype_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ze_actiontype
    ADD CONSTRAINT ze_actiontype_pkey PRIMARY KEY (ze_actiontypeid);


--
-- Name: ze_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ze_type
    ADD CONSTRAINT ze_type_pkey PRIMARY KEY (ze_typeid);


--
-- Name: zprovider_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zprovider
    ADD CONSTRAINT zprovider_pkey PRIMARY KEY (zproviderid);


--
-- Name: zuser_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zuser
    ADD CONSTRAINT zuser_pkey PRIMARY KEY (zuserid);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: e_workflow_etype_leat_neat_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX e_workflow_etype_leat_neat_ix ON public.e_workflow USING btree (e_type, last_e_actiontype, next_e_actiontype);


--
-- Name: index_addresses_on_addressable_type_and_addressable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_addressable_type_and_addressable_id ON public.addresses USING btree (addressable_type, addressable_id);


--
-- Name: index_addresses_on_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_country_id ON public.addresses USING btree (country_id);


--
-- Name: index_birth_data_on_ppatient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_birth_data_on_ppatient_id ON public.birth_data USING btree (ppatient_id);


--
-- Name: index_cas_application_fields_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_application_fields_on_project_id ON public.cas_application_fields USING btree (project_id);


--
-- Name: index_comments_on_commentable_type_and_commentable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable_type_and_commentable_id ON public.comments USING btree (commentable_type, commentable_id);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON public.comments USING btree (user_id);


--
-- Name: index_communications_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_parent_id ON public.communications USING btree (parent_id);


--
-- Name: index_communications_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_project_id ON public.communications USING btree (project_id);


--
-- Name: index_communications_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_recipient_id ON public.communications USING btree (recipient_id);


--
-- Name: index_communications_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_sender_id ON public.communications USING btree (sender_id);


--
-- Name: index_contracts_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_project_id ON public.contracts USING btree (project_id);


--
-- Name: index_contracts_on_project_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_project_state_id ON public.contracts USING btree (project_state_id);


--
-- Name: index_contracts_on_referent_type_and_referent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contracts_on_referent_type_and_referent_id ON public.contracts USING btree (referent_type, referent_id);


--
-- Name: index_cost_recoveries_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cost_recoveries_on_project_id ON public.cost_recoveries USING btree (project_id);


--
-- Name: index_data_item_groups_on_data_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_item_groups_on_data_item_id ON public.data_item_groups USING btree (data_item_id);


--
-- Name: index_data_item_groups_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_item_groups_on_group_id ON public.data_item_groups USING btree (group_id);


--
-- Name: index_data_privacy_impact_assessments_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_privacy_impact_assessments_on_project_id ON public.data_privacy_impact_assessments USING btree (project_id);


--
-- Name: index_data_privacy_impact_assessments_on_project_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_privacy_impact_assessments_on_project_state_id ON public.data_privacy_impact_assessments USING btree (project_state_id);


--
-- Name: index_data_source_items_on_name_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_data_source_items_on_name_and_data_source_id ON public.data_source_items USING btree (name, data_source_id);


--
-- Name: index_data_sources_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_data_sources_on_name ON public.data_sources USING btree (name);


--
-- Name: index_death_data_on_ppatient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_death_data_on_ppatient_id ON public.death_data USING btree (ppatient_id);


--
-- Name: index_dpias_on_ig_assessment_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dpias_on_ig_assessment_status_id ON public.data_privacy_impact_assessments USING btree (ig_assessment_status_id);


--
-- Name: index_dpias_on_referent_type_and_referent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dpias_on_referent_type_and_referent_id ON public.data_privacy_impact_assessments USING btree (referent_type, referent_id);


--
-- Name: index_e_action_on_e_batchid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_e_action_on_e_batchid ON public.e_action USING btree (e_batchid);


--
-- Name: index_e_action_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_e_action_on_status ON public.e_action USING btree (status);


--
-- Name: index_e_batch_on_registryid_and_e_type_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_e_batch_on_registryid_and_e_type_and_provider ON public.e_batch USING btree (registryid, e_type, provider);


--
-- Name: index_enumeration_value_dataset_versions_on_dataset_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enumeration_value_dataset_versions_on_dataset_version_id ON public.enumeration_value_dataset_versions USING btree (dataset_version_id);


--
-- Name: index_era_fields_on_node_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_era_fields_on_node_id ON public.era_fields USING btree (node_id);


--
-- Name: index_error_fingerprints_on_causal_error_fingerprintid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_error_fingerprints_on_causal_error_fingerprintid ON public.error_fingerprints USING btree (causal_error_fingerprintid);


--
-- Name: index_error_logs_on_error_fingerprintid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_error_logs_on_error_fingerprintid ON public.error_logs USING btree (error_fingerprintid);


--
-- Name: index_ev_dataset_versions_on_enumeration_value_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ev_dataset_versions_on_enumeration_value_id ON public.enumeration_value_dataset_versions USING btree (enumeration_value_id);


--
-- Name: index_genetic_sequence_variants_on_genetic_test_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genetic_sequence_variants_on_genetic_test_result_id ON public.genetic_sequence_variants USING btree (genetic_test_result_id);


--
-- Name: index_genetic_test_results_on_molecular_data_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_genetic_test_results_on_molecular_data_id ON public.genetic_test_results USING btree (molecular_data_id);


--
-- Name: index_grants_on_roleable_type_and_roleable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grants_on_roleable_type_and_roleable_id ON public.grants USING btree (roleable_type, roleable_id);


--
-- Name: index_memberships_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_team_id ON public.memberships USING btree (team_id);


--
-- Name: index_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_user_id ON public.memberships USING btree (user_id);


--
-- Name: index_memberships_on_user_id_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_memberships_on_user_id_and_team_id ON public.memberships USING btree (user_id, team_id);


--
-- Name: index_molecular_data_on_ppatient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_molecular_data_on_ppatient_id ON public.molecular_data USING btree (ppatient_id);


--
-- Name: index_node_categories_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_node_categories_on_category_id ON public.node_categories USING btree (category_id);


--
-- Name: index_node_categories_on_node_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_node_categories_on_node_id ON public.node_categories USING btree (node_id);


--
-- Name: index_notifications_on_notification_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notification_template_id ON public.notifications USING btree (notification_template_id);


--
-- Name: index_notifications_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_project_id ON public.notifications USING btree (project_id);


--
-- Name: index_notifications_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_team_id ON public.notifications USING btree (team_id);


--
-- Name: index_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_user_id ON public.notifications USING btree (user_id);


--
-- Name: index_organisations_on_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_on_country_id ON public.organisations USING btree (country_id);


--
-- Name: index_organisations_on_organisation_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organisations_on_organisation_type_id ON public.organisations USING btree (organisation_type_id);


--
-- Name: index_ppatients_on_e_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ppatients_on_e_batch_id ON public.ppatients USING btree (e_batch_id);


--
-- Name: index_ppatients_on_ppatient_rawdata_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ppatients_on_ppatient_rawdata_id ON public.ppatients USING btree (ppatient_rawdata_id);


--
-- Name: index_ppatients_on_pseudo_id1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ppatients_on_pseudo_id1 ON public.ppatients USING btree (pseudo_id1);


--
-- Name: index_ppatients_on_pseudo_id2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ppatients_on_pseudo_id2 ON public.ppatients USING btree (pseudo_id2);


--
-- Name: index_prescription_data_on_bnf_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescription_data_on_bnf_code ON public.prescription_data USING btree (bnf_code);


--
-- Name: index_prescription_data_on_ppatient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescription_data_on_ppatient_id ON public.prescription_data USING btree (ppatient_id);


--
-- Name: index_project_amendments_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_amendments_on_project_id ON public.project_amendments USING btree (project_id);


--
-- Name: index_project_amendments_on_project_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_amendments_on_project_state_id ON public.project_amendments USING btree (project_state_id);


--
-- Name: index_project_attachments_on_attachable_type_and_attachable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_attachments_on_attachable_type_and_attachable_id ON public.project_attachments USING btree (attachable_type, attachable_id);


--
-- Name: index_project_attachments_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_attachments_on_project_id ON public.project_attachments USING btree (project_id);


--
-- Name: index_project_attachments_on_workflow_project_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_attachments_on_workflow_project_state_id ON public.project_attachments USING btree (workflow_project_state_id);


--
-- Name: index_project_classifications_on_classification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_classifications_on_classification_id ON public.project_classifications USING btree (classification_id);


--
-- Name: index_project_classifications_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_classifications_on_project_id ON public.project_classifications USING btree (project_id);


--
-- Name: index_project_comments_on_project_data_source_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_comments_on_project_data_source_item_id ON public.project_comments USING btree (project_data_source_item_id);


--
-- Name: index_project_comments_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_comments_on_project_id ON public.project_comments USING btree (project_id);


--
-- Name: index_project_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_comments_on_user_id ON public.project_comments USING btree (user_id);


--
-- Name: index_project_data_passwords_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_data_passwords_on_project_id ON public.project_data_passwords USING btree (project_id);


--
-- Name: index_project_data_source_items_on_data_source_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_data_source_items_on_data_source_item_id ON public.project_data_source_items USING btree (data_source_item_id);


--
-- Name: index_project_data_source_items_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_data_source_items_on_project_id ON public.project_data_source_items USING btree (project_id);


--
-- Name: index_project_dataset_levels_on_project_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_dataset_levels_on_project_dataset_id ON public.project_dataset_levels USING btree (project_dataset_id);


--
-- Name: index_project_datasets_on_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_datasets_on_dataset_id ON public.project_datasets USING btree (dataset_id);


--
-- Name: index_project_datasets_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_datasets_on_project_id ON public.project_datasets USING btree (project_id);


--
-- Name: index_project_end_uses_on_end_use_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_end_uses_on_end_use_id ON public.project_end_uses USING btree (end_use_id);


--
-- Name: index_project_end_uses_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_end_uses_on_project_id ON public.project_end_uses USING btree (project_id);


--
-- Name: index_project_lawful_bases_on_lawful_basis_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_lawful_bases_on_lawful_basis_id ON public.project_lawful_bases USING btree (lawful_basis_id);


--
-- Name: index_project_lawful_bases_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_lawful_bases_on_project_id ON public.project_lawful_bases USING btree (project_id);


--
-- Name: index_project_memberships_on_membership_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_memberships_on_membership_id ON public.project_memberships USING btree (membership_id);


--
-- Name: index_project_memberships_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_memberships_on_project_id ON public.project_memberships USING btree (project_id);


--
-- Name: index_project_memberships_on_project_id_and_membership_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_memberships_on_project_id_and_membership_id ON public.project_memberships USING btree (project_id, membership_id);


--
-- Name: index_project_nodes_on_node_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_nodes_on_node_id ON public.project_nodes USING btree (node_id);


--
-- Name: index_project_nodes_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_nodes_on_project_id ON public.project_nodes USING btree (project_id);


--
-- Name: index_project_outputs_on_output_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_outputs_on_output_id ON public.project_outputs USING btree (output_id);


--
-- Name: index_project_outputs_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_outputs_on_project_id ON public.project_outputs USING btree (project_id);


--
-- Name: index_project_relationships_on_left_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_relationships_on_left_project_id ON public.project_relationships USING btree (left_project_id);


--
-- Name: index_project_relationships_on_left_project_id_right_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_relationships_on_left_project_id_right_project_id ON public.project_relationships USING btree ((LEAST(left_project_id, right_project_id)), (GREATEST(left_project_id, right_project_id)));


--
-- Name: index_project_relationships_on_right_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_relationships_on_right_project_id ON public.project_relationships USING btree (right_project_id);


--
-- Name: index_project_type_datasets_on_dataset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_type_datasets_on_dataset_id ON public.project_type_datasets USING btree (dataset_id);


--
-- Name: index_project_type_datasets_on_project_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_type_datasets_on_project_type_id ON public.project_type_datasets USING btree (project_type_id);


--
-- Name: index_projects_on_closure_reason_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_closure_reason_id ON public.projects USING btree (closure_reason_id);


--
-- Name: index_projects_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_team_id ON public.projects USING btree (team_id);


--
-- Name: index_projects_on_z_project_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_z_project_status_id ON public.projects USING btree (z_project_status_id);


--
-- Name: index_releases_on_cost_recovery_applied; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_cost_recovery_applied ON public.releases USING btree (cost_recovery_applied);


--
-- Name: index_releases_on_income_received; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_income_received ON public.releases USING btree (income_received);


--
-- Name: index_releases_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_project_id ON public.releases USING btree (project_id);


--
-- Name: index_releases_on_project_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_project_state_id ON public.releases USING btree (project_state_id);


--
-- Name: index_releases_on_referent_type_and_referent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_referent_type_and_referent_id ON public.releases USING btree (referent_type, referent_id);


--
-- Name: index_releases_on_vat_reg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_releases_on_vat_reg ON public.releases USING btree (vat_reg);


--
-- Name: index_team_data_sources_on_data_source_id_and_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_team_data_sources_on_data_source_id_and_team_id ON public.team_data_sources USING btree (data_source_id, team_id);


--
-- Name: index_team_delegate_users_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_delegate_users_on_team_id ON public.team_delegate_users USING btree (team_id);


--
-- Name: index_team_delegate_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_delegate_users_on_user_id ON public.team_delegate_users USING btree (user_id);


--
-- Name: index_teams_on_organisation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_organisation_id ON public.teams USING btree (organisation_id);


--
-- Name: index_user_notifications_on_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notifications_on_notification_id ON public.user_notifications USING btree (notification_id);


--
-- Name: index_user_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notifications_on_user_id ON public.user_notifications USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_title_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_title_id ON public.users USING btree (title_id);


--
-- Name: index_version_associations_on_foreign_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_version_associations_on_foreign_key ON public.version_associations USING btree (foreign_key_name, foreign_key_id);


--
-- Name: index_version_associations_on_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_version_associations_on_version_id ON public.version_associations USING btree (version_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_transaction_id ON public.versions USING btree (transaction_id);


--
-- Name: index_workflow_assignments_on_assigned_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_assignments_on_assigned_user_id ON public.workflow_assignments USING btree (assigned_user_id);


--
-- Name: index_workflow_assignments_on_project_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_assignments_on_project_state_id ON public.workflow_assignments USING btree (project_state_id);


--
-- Name: index_workflow_project_states_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_project_states_on_project_id ON public.workflow_project_states USING btree (project_id);


--
-- Name: index_workflow_project_states_on_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_project_states_on_state_id ON public.workflow_project_states USING btree (state_id);


--
-- Name: index_workflow_project_states_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_project_states_on_user_id ON public.workflow_project_states USING btree (user_id);


--
-- Name: index_workflow_transitions_on_from_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_transitions_on_from_state_id ON public.workflow_transitions USING btree (from_state_id);


--
-- Name: index_workflow_transitions_on_next_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_transitions_on_next_state_id ON public.workflow_transitions USING btree (next_state_id);


--
-- Name: index_workflow_transitions_on_project_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_transitions_on_project_type_id ON public.workflow_transitions USING btree (project_type_id);


--
-- Name: index_xml_type_xml_attributes_on_xml_attribute_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_xml_type_xml_attributes_on_xml_attribute_id ON public.xml_type_xml_attributes USING btree (xml_attribute_id);


--
-- Name: index_xml_type_xml_attributes_on_xml_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_xml_type_xml_attributes_on_xml_type_id ON public.xml_type_xml_attributes USING btree (xml_type_id);


--
-- Name: index_z_project_statuses_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_z_project_statuses_on_name ON public.z_project_statuses USING btree (name);


--
-- Name: index_z_team_statuses_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_z_team_statuses_on_name ON public.z_team_statuses USING btree (name);


--
-- Name: index_z_user_statuses_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_z_user_statuses_on_name ON public.z_user_statuses USING btree (name);


--
-- Name: fk_rails_01a7c8fd36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_01a7c8fd36 FOREIGN KEY (z_project_status_id) REFERENCES public.z_project_statuses(id);


--
-- Name: fk_rails_02fcb709b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT fk_rails_02fcb709b7 FOREIGN KEY (income_received) REFERENCES public.propositions(id);


--
-- Name: fk_rails_03de2dc08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_03de2dc08c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_057ca0952e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_type_datasets
    ADD CONSTRAINT fk_rails_057ca0952e FOREIGN KEY (project_type_id) REFERENCES public.project_types(id);


--
-- Name: fk_rails_091f2f7877; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_comments
    ADD CONSTRAINT fk_rails_091f2f7877 FOREIGN KEY (project_data_source_item_id) REFERENCES public.project_data_source_items(id);


--
-- Name: fk_rails_0956ea0ead; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_0956ea0ead FOREIGN KEY (data_processor_country_id) REFERENCES public.countries(id);


--
-- Name: fk_rails_09e1600f8b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zuser
    ADD CONSTRAINT fk_rails_09e1600f8b FOREIGN KEY (qa_supervisorid) REFERENCES public.zuser(zuserid);


--
-- Name: fk_rails_0de10d2128; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_datasets
    ADD CONSTRAINT fk_rails_0de10d2128 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_0dea23f76a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_0dea23f76a FOREIGN KEY (organisation_country_id) REFERENCES public.countries(id);


--
-- Name: fk_rails_0e9ad281ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_privacy_impact_assessments
    ADD CONSTRAINT fk_rails_0e9ad281ee FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_0f644da0f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonymisation_keys
    ADD CONSTRAINT fk_rails_0f644da0f9 FOREIGN KEY (e_type) REFERENCES public.ze_type(ze_typeid);


--
-- Name: fk_rails_0f88cd560a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xml_type_xml_attributes
    ADD CONSTRAINT fk_rails_0f88cd560a FOREIGN KEY (xml_type_id) REFERENCES public.xml_types(id);


--
-- Name: fk_rails_0fd1cb2692; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT fk_rails_0fd1cb2692 FOREIGN KEY (organisation_id) REFERENCES public.organisations(id);


--
-- Name: fk_rails_106f1fa28a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_batch
    ADD CONSTRAINT fk_rails_106f1fa28a FOREIGN KEY (registryid) REFERENCES public.zprovider(zproviderid);


--
-- Name: fk_rails_12637d7d97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_type_datasets
    ADD CONSTRAINT fk_rails_12637d7d97 FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);


--
-- Name: fk_rails_1528c8995c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_privacy_impact_assessments
    ADD CONSTRAINT fk_rails_1528c8995c FOREIGN KEY (ig_assessment_status_id) REFERENCES public.ig_assessment_statuses(id);


--
-- Name: fk_rails_17c5707da7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_action
    ADD CONSTRAINT fk_rails_17c5707da7 FOREIGN KEY (e_actiontype) REFERENCES public.ze_actiontype(ze_actiontypeid);


--
-- Name: fk_rails_1802646fee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_datasets
    ADD CONSTRAINT fk_rails_1802646fee FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);


--
-- Name: fk_rails_18b611e244; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_memberships
    ADD CONSTRAINT fk_rails_18b611e244 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_1c69a91756; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT fk_rails_1c69a91756 FOREIGN KEY (project_state_id) REFERENCES public.workflow_project_states(id);


--
-- Name: fk_rails_1efa5d208d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_1efa5d208d FOREIGN KEY (applicant_title_id) REFERENCES public.titles(id);


--
-- Name: fk_rails_224247fecc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_224247fecc FOREIGN KEY (security_assurance_id) REFERENCES public.security_assurances(id);


--
-- Name: fk_rails_256ad522e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_amendments
    ADD CONSTRAINT fk_rails_256ad522e8 FOREIGN KEY (project_state_id) REFERENCES public.workflow_project_states(id);


--
-- Name: fk_rails_258942a711; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_nodes
    ADD CONSTRAINT fk_rails_258942a711 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_265da3b194; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppatients
    ADD CONSTRAINT fk_rails_265da3b194 FOREIGN KEY (pseudonymisation_keyid) REFERENCES public.pseudonymisation_keys(pseudonymisation_keyid);


--
-- Name: fk_rails_29751db00d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_passwords
    ADD CONSTRAINT fk_rails_29751db00d FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_2989890e74; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_2989890e74 FOREIGN KEY (rec_committee_id) REFERENCES public.rec_committees(id);


--
-- Name: fk_rails_2df7f418f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_workflow
    ADD CONSTRAINT fk_rails_2df7f418f6 FOREIGN KEY (provider) REFERENCES public.zprovider(zproviderid);


--
-- Name: fk_rails_2f912bd782; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_dataset_levels
    ADD CONSTRAINT fk_rails_2f912bd782 FOREIGN KEY (project_dataset_id) REFERENCES public.project_datasets(id);


--
-- Name: fk_rails_35cad80142; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grants
    ADD CONSTRAINT fk_rails_35cad80142 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_37572502ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppatients
    ADD CONSTRAINT fk_rails_37572502ce FOREIGN KEY (e_batch_id) REFERENCES public.e_batch(e_batchid);


--
-- Name: fk_rails_37d057eb4d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_37d057eb4d FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: fk_rails_3d10ee277d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_3d10ee277d FOREIGN KEY (s251_exemption_id) REFERENCES public.common_law_exemptions(id);


--
-- Name: fk_rails_3dd8aff4eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription_data
    ADD CONSTRAINT fk_rails_3dd8aff4eb FOREIGN KEY (ppatient_id) REFERENCES public.ppatients(id) ON DELETE CASCADE;


--
-- Name: fk_rails_41c5e93ac9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communications
    ADD CONSTRAINT fk_rails_41c5e93ac9 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_453b679a0f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xml_type_xml_attributes
    ADD CONSTRAINT fk_rails_453b679a0f FOREIGN KEY (xml_attribute_id) REFERENCES public.xml_attributes(id);


--
-- Name: fk_rails_47fe2a0596; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT fk_rails_47fe2a0596 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_4d63e64586; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_relationships
    ADD CONSTRAINT fk_rails_4d63e64586 FOREIGN KEY (right_project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_4db7b1360c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT fk_rails_4db7b1360c FOREIGN KEY (assigning_user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_55a5acccd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_workflow
    ADD CONSTRAINT fk_rails_55a5acccd7 FOREIGN KEY (e_type) REFERENCES public.ze_type(ze_typeid);


--
-- Name: fk_rails_575368d182; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_575368d182 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_57c32f644b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_delegate_users
    ADD CONSTRAINT fk_rails_57c32f644b FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: fk_rails_585dba9f11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_action
    ADD CONSTRAINT fk_rails_585dba9f11 FOREIGN KEY (e_batchid) REFERENCES public.e_batch(e_batchid);


--
-- Name: fk_rails_58ce3a5db2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_58ce3a5db2 FOREIGN KEY (organisation_type_id) REFERENCES public.organisation_types(id);


--
-- Name: fk_rails_594ddba59b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_lawful_bases
    ADD CONSTRAINT fk_rails_594ddba59b FOREIGN KEY (lawful_basis_id) REFERENCES public.lawful_bases(id);


--
-- Name: fk_rails_59f4a418b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_59f4a418b1 FOREIGN KEY (processing_territory_id) REFERENCES public.processing_territories(id);


--
-- Name: fk_rails_59fdc180ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_59fdc180ba FOREIGN KEY (funder_country_id) REFERENCES public.countries(id);


--
-- Name: fk_rails_5e6fb45273; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communications
    ADD CONSTRAINT fk_rails_5e6fb45273 FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: fk_rails_5f38890297; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_source_items
    ADD CONSTRAINT fk_rails_5f38890297 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_6289dbcb3a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communications
    ADD CONSTRAINT fk_rails_6289dbcb3a FOREIGN KEY (recipient_id) REFERENCES public.users(id);


--
-- Name: fk_rails_64fb4d33de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT fk_rails_64fb4d33de FOREIGN KEY (from_state_id) REFERENCES public.workflow_states(id);


--
-- Name: fk_rails_66c2d703f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonymisation_keys
    ADD CONSTRAINT fk_rails_66c2d703f8 FOREIGN KEY (provider) REFERENCES public.zprovider(zproviderid);


--
-- Name: fk_rails_6746a71977; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT fk_rails_6746a71977 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_691353c0f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_item_groups
    ADD CONSTRAINT fk_rails_691353c0f1 FOREIGN KEY (data_item_id) REFERENCES public.data_items(id);


--
-- Name: fk_rails_69adf6173e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT fk_rails_69adf6173e FOREIGN KEY (country_id) REFERENCES public.countries(id);


--
-- Name: fk_rails_6b92dcab38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_6b92dcab38 FOREIGN KEY (closure_reason_id) REFERENCES public.closure_reasons(id);


--
-- Name: fk_rails_6c003d8e85; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_batch
    ADD CONSTRAINT fk_rails_6c003d8e85 FOREIGN KEY (provider) REFERENCES public.zprovider(zproviderid);


--
-- Name: fk_rails_6d202b9e83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_data_sources
    ADD CONSTRAINT fk_rails_6d202b9e83 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: fk_rails_72929ef0ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_comments
    ADD CONSTRAINT fk_rails_72929ef0ea FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_7641fc5f40; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_outputs
    ADD CONSTRAINT fk_rails_7641fc5f40 FOREIGN KEY (output_id) REFERENCES public.outputs(id);


--
-- Name: fk_rails_7b7111c3a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organisations
    ADD CONSTRAINT fk_rails_7b7111c3a1 FOREIGN KEY (organisation_type_id) REFERENCES public.organisation_types(id);


--
-- Name: fk_rails_7dcc851597; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_relationships
    ADD CONSTRAINT fk_rails_7dcc851597 FOREIGN KEY (left_project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_7f4df6fc8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT fk_rails_7f4df6fc8f FOREIGN KEY (cost_recovery_applied) REFERENCES public.propositions(id);


--
-- Name: fk_rails_7f6c9f24a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_end_uses
    ADD CONSTRAINT fk_rails_7f6c9f24a0 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_8168f79a67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_nodes
    ADD CONSTRAINT fk_rails_8168f79a67 FOREIGN KEY (node_id) REFERENCES public.nodes(id);


--
-- Name: fk_rails_8677aa8853; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_categories
    ADD CONSTRAINT fk_rails_8677aa8853 FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: fk_rails_886f8f893f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_886f8f893f FOREIGN KEY (assigned_user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_89113d837c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.death_data
    ADD CONSTRAINT fk_rails_89113d837c FOREIGN KEY (ppatient_id) REFERENCES public.ppatients(id) ON DELETE CASCADE;


--
-- Name: fk_rails_897708b17a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_lawful_bases
    ADD CONSTRAINT fk_rails_897708b17a FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_8bc6a1d7df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_outputs
    ADD CONSTRAINT fk_rails_8bc6a1d7df FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_8d4eddcae3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_project_states
    ADD CONSTRAINT fk_rails_8d4eddcae3 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_8e64e75901; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT fk_rails_8e64e75901 FOREIGN KEY (vat_reg) REFERENCES public.propositions(id);


--
-- Name: fk_rails_911e50adef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_memberships
    ADD CONSTRAINT fk_rails_911e50adef FOREIGN KEY (membership_id) REFERENCES public.memberships(id);


--
-- Name: fk_rails_91e19c3025; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_delegate_users
    ADD CONSTRAINT fk_rails_91e19c3025 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_925a1276f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enumeration_value_dataset_versions
    ADD CONSTRAINT fk_rails_925a1276f9 FOREIGN KEY (enumeration_value_id) REFERENCES public.enumeration_values(id);


--
-- Name: fk_rails_973312a1aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppatients
    ADD CONSTRAINT fk_rails_973312a1aa FOREIGN KEY (ppatient_rawdata_id) REFERENCES public.ppatient_rawdata(ppatient_rawdataid);


--
-- Name: fk_rails_97be9726bf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_batch
    ADD CONSTRAINT fk_rails_97be9726bf FOREIGN KEY (e_type) REFERENCES public.ze_type(ze_typeid);


--
-- Name: fk_rails_99326fb65d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_99326fb65d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_a05624f966; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_categories
    ADD CONSTRAINT fk_rails_a05624f966 FOREIGN KEY (node_id) REFERENCES public.nodes(id);


--
-- Name: fk_rails_a060e2d739; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_comments
    ADD CONSTRAINT fk_rails_a060e2d739 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_a19c255427; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_project_states
    ADD CONSTRAINT fk_rails_a19c255427 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_a89310a7eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_a89310a7eb FOREIGN KEY (processing_territory_outsourced_id) REFERENCES public.processing_territories(id);


--
-- Name: fk_rails_aad4e12831; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT fk_rails_aad4e12831 FOREIGN KEY (next_state_id) REFERENCES public.workflow_states(id);


--
-- Name: fk_rails_ac47ea9a96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_source_items
    ADD CONSTRAINT fk_rails_ac47ea9a96 FOREIGN KEY (data_source_item_id) REFERENCES public.data_source_items(id);


--
-- Name: fk_rails_ae2aedcfaf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_ae2aedcfaf FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: fk_rails_b007b76cfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT fk_rails_b007b76cfa FOREIGN KEY (project_state_id) REFERENCES public.workflow_project_states(id);


--
-- Name: fk_rails_b027420c08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_attachments
    ADD CONSTRAINT fk_rails_b027420c08 FOREIGN KEY (workflow_project_state_id) REFERENCES public.workflow_project_states(id);


--
-- Name: fk_rails_b080fb4855; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_b5082704f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_assignments
    ADD CONSTRAINT fk_rails_b5082704f2 FOREIGN KEY (assigned_user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_b79fdbecac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_data_sources
    ADD CONSTRAINT fk_rails_b79fdbecac FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: fk_rails_b7e1584aaf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_workflow
    ADD CONSTRAINT fk_rails_b7e1584aaf FOREIGN KEY (next_e_actiontype) REFERENCES public.ze_actiontype(ze_actiontypeid);


--
-- Name: fk_rails_bed300084f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_attachments
    ADD CONSTRAINT fk_rails_bed300084f FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_c26f5d62f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_c26f5d62f9 FOREIGN KEY (sponsor_country_id) REFERENCES public.countries(id);


--
-- Name: fk_rails_c2ebe2d7b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.molecular_data
    ADD CONSTRAINT fk_rails_c2ebe2d7b1 FOREIGN KEY (ppatient_id) REFERENCES public.ppatients(id) ON DELETE CASCADE;


--
-- Name: fk_rails_c9c498759d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communications
    ADD CONSTRAINT fk_rails_c9c498759d FOREIGN KEY (parent_id) REFERENCES public.communications(id);


--
-- Name: fk_rails_cdbff2ee9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT fk_rails_cdbff2ee9e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: fk_rails_d238d8ef07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT fk_rails_d238d8ef07 FOREIGN KEY (notification_id) REFERENCES public.notifications(id);


--
-- Name: fk_rails_d2549c7f67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_fingerprints
    ADD CONSTRAINT fk_rails_d2549c7f67 FOREIGN KEY (causal_error_fingerprintid) REFERENCES public.error_fingerprints(error_fingerprintid);


--
-- Name: fk_rails_e22bab0c77; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_amendments
    ADD CONSTRAINT fk_rails_e22bab0c77 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: fk_rails_e829d9cb9c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_e829d9cb9c FOREIGN KEY (programme_support_id) REFERENCES public.programme_supports(id);


--
-- Name: fk_rails_e863729edc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_privacy_impact_assessments
    ADD CONSTRAINT fk_rails_e863729edc FOREIGN KEY (project_state_id) REFERENCES public.workflow_project_states(id);


--
-- Name: fk_rails_e9277efd4e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_e9277efd4e FOREIGN KEY (title_id) REFERENCES public.titles(id);


--
-- Name: fk_rails_e93db6165d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_e93db6165d FOREIGN KEY (legal_gateway_id) REFERENCES public.legal_gateways(id);


--
-- Name: fk_rails_eb7e144634; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.birth_data
    ADD CONSTRAINT fk_rails_eb7e144634 FOREIGN KEY (ppatient_id) REFERENCES public.ppatients(id) ON DELETE CASCADE;


--
-- Name: fk_rails_ec7c231bc3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_item_groups
    ADD CONSTRAINT fk_rails_ec7c231bc3 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: fk_rails_ecc227a0c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_ecc227a0c2 FOREIGN KEY (team_id) REFERENCES public.teams(id);


--
-- Name: fk_rails_f21be4c468; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_project_states
    ADD CONSTRAINT fk_rails_f21be4c468 FOREIGN KEY (state_id) REFERENCES public.workflow_states(id);


--
-- Name: fk_rails_f5b0e1ef2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_f5b0e1ef2f FOREIGN KEY (security_assurance_outsourced_id) REFERENCES public.security_assurances(id);


--
-- Name: fk_rails_f6a5e2c138; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_end_uses
    ADD CONSTRAINT fk_rails_f6a5e2c138 FOREIGN KEY (end_use_id) REFERENCES public.end_uses(id);


--
-- Name: fk_rails_f6d853e80c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.releases
    ADD CONSTRAINT fk_rails_f6d853e80c FOREIGN KEY (project_state_id) REFERENCES public.workflow_project_states(id);


--
-- Name: fk_rails_f9c6915550; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enumeration_value_dataset_versions
    ADD CONSTRAINT fk_rails_f9c6915550 FOREIGN KEY (dataset_version_id) REFERENCES public.dataset_versions(id);


--
-- Name: fk_rails_fbc93a3129; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_transitions
    ADD CONSTRAINT fk_rails_fbc93a3129 FOREIGN KEY (project_type_id) REFERENCES public.project_types(id);


--
-- Name: fk_rails_fd9c40292c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.e_workflow
    ADD CONSTRAINT fk_rails_fd9c40292c FOREIGN KEY (last_e_actiontype) REFERENCES public.ze_actiontype(ze_actiontypeid);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20160115160033'),
('20160115160034'),
('20160115160656'),
('20160212111057'),
('20160307220719'),
('20160511133728'),
('20160511133742'),
('20160511133749'),
('20160511133750'),
('20160511133751'),
('20160511133752'),
('20160511133757'),
('20160520113610'),
('20160520113611'),
('20160520113612'),
('20160520113613'),
('20160520113614'),
('20160520113615'),
('20160520113616'),
('20160520113617'),
('20160713151550'),
('20160714091934'),
('20160714095539'),
('20160718085652'),
('20160718092418'),
('20160718092422'),
('20160718092433'),
('20160718134311'),
('20160718134617'),
('20160718134759'),
('20160718143023'),
('20160719122851'),
('20160720083512'),
('20160720090123'),
('20160720091850'),
('20160721071014'),
('20160721071015'),
('20160721095400'),
('20160721095750'),
('20160725094053'),
('20160725094915'),
('20160725095042'),
('20160725095128'),
('20160725095131'),
('20160726081122'),
('20160728092641'),
('20160729084451'),
('20160801124457'),
('20160804081707'),
('20160808121714'),
('20160811093550'),
('20160811105716'),
('20160825104758'),
('20160902133853'),
('20160902133943'),
('20160913110454'),
('20160914142742'),
('20160915141059'),
('20160919145351'),
('20160919145352'),
('20160921145353'),
('20160922153233'),
('20160922153525'),
('20160927143106'),
('20161012110508'),
('20161012110621'),
('20161012134204'),
('20161019132333'),
('20161021100040'),
('20161021101330'),
('20161024104938'),
('20161209100153'),
('20161219155406'),
('20161230140541'),
('20170117140543'),
('20170123144552'),
('20170124092048'),
('20170217091013'),
('20170217120432'),
('20170217120435'),
('20170217141601'),
('20170217155008'),
('20170221095732'),
('20170222094613'),
('20170222094616'),
('20170222105118'),
('20170329142930'),
('20170330131357'),
('20170330131403'),
('20170330131407'),
('20170330131410'),
('20170426112620'),
('20170619134351'),
('20170619135526'),
('20170803120718'),
('20170825091547'),
('20170830141411'),
('20170830145352'),
('20170905101502'),
('20170905124431'),
('20170922142505'),
('20170922144830'),
('20170922152439'),
('20171006121417'),
('20171009133405'),
('20171019124047'),
('20171029164438'),
('20171110152205'),
('20171110152215'),
('20171110155758'),
('20171113102021'),
('20171113153105'),
('20171114160306'),
('20171214122852'),
('20180108105317'),
('20180108145448'),
('20180119164128'),
('20180127175347'),
('20180128181744'),
('20180129101918'),
('20180129112823'),
('20180216150430'),
('20180319161101'),
('20180417102840'),
('20180809105358'),
('20180821150505'),
('20180829083821'),
('20180907153141'),
('20181029123249'),
('20181109102214'),
('20181114114129'),
('20181114114140'),
('20181114114147'),
('20181114114213'),
('20181114114223'),
('20181114114235'),
('20181114114405'),
('20181114114431'),
('20181114114441'),
('20181114153901'),
('20181115164857'),
('20181116164907'),
('20181205160046'),
('20181205160124'),
('20181205160138'),
('20181208101915'),
('20181220090937'),
('20181221110625'),
('20181228140404'),
('20181228140421'),
('20181228140438'),
('20181228140448'),
('20181228140504'),
('20181228140514'),
('20181228142755'),
('20181228142806'),
('20181228143226'),
('20181228143238'),
('20181228143508'),
('20181228143518'),
('20181228143833'),
('20181228143843'),
('20181231084942'),
('20181231084953'),
('20181231085534'),
('20181231085544'),
('20181231092315'),
('20181231092325'),
('20181231121657'),
('20181231121658'),
('20181231132110'),
('20181231132123'),
('20190104082842'),
('20190104083944'),
('20190104094447'),
('20190104094456'),
('20190106133744'),
('20190106134209'),
('20190107071225'),
('20190107071248'),
('20190107071339'),
('20190107083512'),
('20190110133901'),
('20190110133919'),
('20190114133536'),
('20190114142324'),
('20190114142537'),
('20190118141504'),
('20190121072958'),
('20190121073023'),
('20190121130452'),
('20190121130453'),
('20190122104430'),
('20190123080519'),
('20190123080527'),
('20190123081259'),
('20190123081313'),
('20190123103912'),
('20190123114455'),
('20190123115057'),
('20190124104536'),
('20190129110729'),
('20190129120009'),
('20190129131012'),
('20190129131035'),
('20190214105943'),
('20190214111100'),
('20190214111104'),
('20190214172115'),
('20190218140722'),
('20190219000000'),
('20190222124749'),
('20190222125106'),
('20190222161400'),
('20190225122829'),
('20190228134900'),
('20190305131135'),
('20190305131154'),
('20190305131456'),
('20190305142645'),
('20190305145412'),
('20190305151238'),
('20190305153539'),
('20190306092501'),
('20190306092908'),
('20190502112543'),
('20190502113107'),
('20190502113122'),
('20190502113807'),
('20190502114011'),
('20190503103742'),
('20190503104654'),
('20190503114646'),
('20190503114658'),
('20190503115223'),
('20190503122939'),
('20190621150826'),
('20190626180218'),
('20190702124052'),
('20190723092630'),
('20190730111746'),
('20190730141228'),
('20190806115710'),
('20190806120712'),
('20190806142540'),
('20190807000001'),
('20190903131044'),
('20190909151837'),
('20190909152211'),
('20190910185955'),
('20190910190012'),
('20190910190858'),
('20190910190909'),
('20190910190925'),
('20190911000000'),
('20191018103554'),
('20191028163729'),
('20191101101859'),
('20191101143213'),
('20191101143612'),
('20191104152702'),
('20191107130112'),
('20191107150829'),
('20191108145152'),
('20191109150501'),
('20191109172922'),
('20191111092449'),
('20191111143622'),
('20191112112413'),
('20191112115305'),
('20191113112611'),
('20191115134127'),
('20191119130520'),
('20191122083645'),
('20191122083714'),
('20191122083733'),
('20191122083805'),
('20191122084824'),
('20191122090214'),
('20191125114717'),
('20191125192533'),
('20191125192604'),
('20191125192928'),
('20191126103217'),
('20191127120931'),
('20191129094923'),
('20191129110232'),
('20191129125618'),
('20191203102723'),
('20191203102908'),
('20191203111202'),
('20191204132624'),
('20191204145500'),
('20191205113045'),
('20191205133453'),
('20191205133952'),
('20191207111420'),
('20191207120325'),
('20191207172245'),
('20191208162835'),
('20191210111419'),
('20191211141751'),
('20191211142012'),
('20191211142142'),
('20191216094549'),
('20191216104635'),
('20191216105433'),
('20191217104937'),
('20191217105044'),
('20191217105544'),
('20191219155852'),
('20191220120902'),
('20191220152722'),
('20191220153402'),
('20200113091111'),
('20200113092313'),
('20200113094223'),
('20200129140445'),
('20200130104000'),
('20200130132012'),
('20200130141706'),
('20200130154306'),
('20200130161925'),
('20200131091327'),
('20200206155620'),
('20200211160019'),
('20200212110036'),
('20200212112914'),
('20200214154001'),
('20200218151458'),
('20200220103812'),
('20200302115852'),
('20200302132236'),
('20200302135750'),
('20200302153327'),
('20200309144350'),
('20200313095921'),
('20200324120609'),
('20200324120610'),
('20200324121133'),
('20200324121530'),
('20200327092835'),
('20200330120935'),
('20200330130229'),
('20200407094200'),
('20200407094201'),
('20200407094202'),
('20200409071350'),
('20200409115310'),
('20200414100059'),
('20200414102604'),
('20200414123201'),
('20200414123202'),
('20200414123203'),
('20200414130612'),
('20200414133115'),
('20200622142622'),
('20200727085748'),
('20200819162818'),
('20200820153644'),
('20200821134109'),
('20200821134630'),
('20201014120225'),
('20201014122944'),
('20201015135259'),
('20201018132536'),
('20201018132733'),
('20201018134038'),
('20201018134152'),
('20201106153234'),
('20201106153256'),
('20201106153309'),
('20201113112942'),
('20201117110141'),
('20201117113702'),
('20201117113815'),
('20201118105849'),
('20201118133709'),
('20201118154616'),
('20201119113713'),
('20201119132335'),
('20201120112450'),
('20201125113756'),
('20201126114719'),
('20201126114922'),
('20201126115056'),
('20210104125759'),
('20210104144033'),
('20210105125403'),
('20210112164055'),
('20210201115059'),
('20210201115318'),
('20210201122226'),
('20210201122300'),
('20210202173000'),
('20210208111919'),
('20210208112318'),
('20210208172519'),
('20210311083858'),
('20210312171649'),
('20210315142901'),
('20210316142127'),
('20210331115138'),
('20210407120512'),
('20210408152005'),
('20210414134929'),
('20210415143021'),
('20210506093309'),
('20210513095643'),
('20210514110933'),
('20210518103646'),
('20210518150518'),
('20210519161222'),
('20210519161356'),
('20210521102230'),
('20210526131356'),
('20210603114230'),
('20210603155912'),
('20210604102124'),
('20210615101111'),
('20210615104916'),
('20210617140742'),
('20210628103955'),
('20210727121915'),
('20210727121924'),
('20210727121941'),
('20210728114812'),
('20210728114817'),
('20210728114821'),
('20210728115617'),
('20210728115621'),
('20210728115625'),
('20210728140133'),
('20210728140140'),
('20210728140147'),
('20210728140306'),
('20210728140310'),
('20210728140313'),
('20210730080619'),
('20210730103014'),
('20210730115722'),
('20210810112702'),
('20210811081605'),
('20210812154107'),
('20210820162108'),
('20210824150840'),
('20210906151948');
