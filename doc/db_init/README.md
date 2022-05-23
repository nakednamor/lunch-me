# Database initialization

The initial database can be created using the following steps.

## Prerequisite

- sqlite3 installed

## Database creation

Execute the following commands to create the application database:

1. sqlite3 lunch_me_db < create_database.sql
2. sqlite3 lunch_me_db 'UPDATE recipes SET url = null WHERE url = "";'
3. sqlite3 lunch_me_db 'UPDATE recipes SET image = null WHERE image = "";'
4. sqlite3 lunch_me_db 'UPDATE recipes SET image_photo = null WHERE image_photo = "";'
5. sqlite3 lunch_me_db 'UPDATE recipes SET content_photo = null WHERE content_photo = "";'

By this you'll also start the sqlite3 console where you can work with the database e.g. querying
like:

`select ltg.label, lt.label from tags t join localized_tags lt on lt.tag = t.id join tag_groups tg on tg.id = t.tag_group join localized_tag_groups ltg on ltg.tag_group = tg.id where ltg.lang = "en" and lt.lang = "en";`

The database file ('lunch_me_db') needs to be stored in the 'assets/db' directory. In addition you
also need to execute the following command on the project root level - this will generate necessary
classes to work with the database (using drift).

`flutter packages pub run build_runner build`

Tests can be executed by using:

`flutter test -j, --concurrency=1`