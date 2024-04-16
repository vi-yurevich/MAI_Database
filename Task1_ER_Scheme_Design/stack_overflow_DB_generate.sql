create type record_type as enum (
    'Question',
    'Answer',
    'Comment',
    'Edition');

create table "Users"
(
    user_id           integer           not null
        constraint "Users_pk"
            primary key,
    nickname          text              not null
        constraint "Users_pk2"
            unique,
    email             text              not null
        constraint "Users_pk3"
            unique,
    reputation_score  integer default 0 not null,
    golden_badges     integer default 0 not null,
    silver_badges     integer default 0 not null,
    bronze_badges     integer default 0 not null,
    registration_date date              not null,
    last_seen         timestamp         not null
);

create table "Forum_Record"
(
    record_id        integer           not null
        constraint "Forum_Record_pk"
            primary key,
    record_type      record_type       not null,
    message          text              not null,
    score            integer default 0 not null,
    views            integer default 0 not null,
    parent_record_id integer
        constraint "Forum_Record_Forum_Record_record_id_fk"
            references "Forum_Record",
    creation_date    timestamp         not null,
    correct_answer   boolean,
    accepted         boolean,
    question_title   text
);

create table "User_Forum_Record"
(
    author_id integer not null
        constraint "User_Forum_Record_Users_user_id_fk"
            references "Users",
    record_id integer not null
        constraint "User_Forum_Record_Forum_Record_record_id_fk"
            references "Forum_Record",
    constraint "User_Forum_Record_pk"
        primary key (author_id, record_id)
);

create table "Tag"
(
    tag_id      integer not null
        constraint "Tag_pk3"
            primary key,
    tag_text    text    not null,
    question_id integer not null
        constraint "Tag_Forum_Record_record_id_fk"
            references "Forum_Record",
    constraint "Tag_pk"
        unique (question_id, tag_text),
    constraint "Tag_pk2"
        unique (tag_text, question_id)
);