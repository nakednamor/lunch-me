PRAGMA foreign_keys = ON;

create table languages ( id int primary key, lang varchar(3) not null, unique(lang) );

create table tag_groups ( id int primary key, system boolean not null check (system in (0,1)) );

create table localized_tag_groups (id int primary key, tag_group int not null, lang int not null, label varchar(50) not null,
foreign key(tag_group) references tag_groups(id) on delete cascade, foreign key(lang) references languages(id) on delete cascade, unique (tag_group, lang) );

create table tags ( id int primary key, tag_group int not null, system boolean not null check (system in (0,1)), foreign key(tag_group) references tag_groups(id) on delete cascade);

create table localized_tags (id int primary key, tag int not null, lang int not null, label varchar(50) not null, foreign key(tag) references tags(id) on delete cascade, foreign key(lang) references languages(id) on delete cascade, unique (tag, lang) );

.mode csv

.import lunch_me_locales.csv languages

.import lunch_me_tag_groups.csv tag_groups

.import lunch_me_localized_tag_groups.csv localized_tag_groups

.import lunch_me_tags.csv tags

.import lunch_me_localized_tags.csv localized_tags