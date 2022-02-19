PRAGMA foreign_keys = ON;

create table languages ( id integer primary key autoincrement, lang varchar(3) not null, unique(lang) );

create table tag_groups ( id integer primary key autoincrement, ordering int not null, unique(ordering) );

create table localized_tag_groups (id integer primary key autoincrement, tag_group int not null, lang int not null, label varchar(50) not null, foreign key(tag_group) references tag_groups(id) on delete cascade, foreign key(lang) references languages(id) on delete cascade, unique (tag_group, lang) );

create table tags ( id integer primary key autoincrement, tag_group int not null, ordering int not null, unique(tag_group, ordering), foreign key(tag_group) references tag_groups(id) on delete cascade);

create table localized_tags ( id integer primary key autoincrement, tag int not null, lang int not null, label varchar(50) not null, foreign key(tag) references tags(id) on delete cascade, foreign key(lang) references languages(id) on delete cascade, unique (tag, lang) );

create table recipes ( id integer primary key autoincrement, name varchar(50) not null, type int not null, url varchar(255), image varchar(255) );

create table recipe_has_tag ( recipe int not null, tag int not null, primary key (recipe, tag) foreign key(recipe) references recipes(id) on delete cascade, foreign key(tag) references tags(id) on delete cascade );

.mode csv

.import lunch_me_locales.csv languages

.import lunch_me_tag_groups.csv tag_groups

.import lunch_me_localized_tag_groups.csv localized_tag_groups

.import lunch_me_tags.csv tags

.import lunch_me_localized_tags.csv localized_tags

.import lunch_me_recipes.csv recipes

.import lunch_me_recipe_has_tag.csv recipe_has_tag