PRAGMA foreign_keys = ON;

create table tag_groups ( id integer primary key autoincrement, ordering int not null, label varchar(50) not null, unique(ordering), unique(label) );

create table tags ( id integer primary key autoincrement, tag_group int not null, ordering int not null, label varchar(50) not null, unique(tag_group, ordering), unique(tag_group, label), foreign key(tag_group) references tag_groups(id) on delete cascade );

create table recipes ( id integer primary key autoincrement, name varchar(50) not null, type int not null, url varchar(255), image varchar(255), unique(name, type) );

create table recipe_has_tag ( recipe int not null, tag int not null, primary key (recipe, tag) foreign key(recipe) references recipes(id) on delete cascade, foreign key(tag) references tags(id) on delete cascade );

create table photo ( id integer primary key autoincrement, uuid char(36) not null, ordering int not null, content_photo int not null check ( content_photo in (0,1) ), recipe int not null, unique(uuid, ordering, content_photo, recipe), unique(ordering, content_photo, recipe), foreign key(recipe) references recipes(id) on delete cascade );

.mode csv

.import lunch_me_tag_groups.csv tag_groups

.import lunch_me_tags.csv tags

.import lunch_me_recipes.csv recipes

.import lunch_me_recipe_has_tag.csv recipe_has_tag