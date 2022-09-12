# Database initialization

The initial database can be created using the following steps.

## Prerequisite

- sqlite3 installed

## Database creation

Execute the following commands to create the application database:

1. sqlite3 lunch_me_db < create_database.sql
2. sqlite3 lunch_me_db 'UPDATE recipes SET url = null WHERE url = "";'
3. sqlite3 lunch_me_db 'UPDATE recipes SET image = null WHERE image = "";'

By this you'll also start the sqlite3 console where you can work with the database e.g. querying
like:

`select tg.label, t.label from tags t join tag_groups tg on tg.id = t.tag_group;`

The database file ('lunch_me_db') needs to be stored in the 'assets/db' directory. In addition you
also need to execute the following command on the project root level - this will generate necessary
classes to work with the database (using drift).

```bash
flutter packages pub run build_runner build
```

Tests can be executed by using:

```bash
flutter test -j, --concurrency=1
```