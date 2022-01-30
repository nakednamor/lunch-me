# Database initialization
The initial database can be created using the following steps.

## Prerequisite
- sqlite3 installed

## Database creation
Execute the following command to create the application database:

1. sqlite3 lunch_me_db < create_database.sql

By this you'll also start the sqlite3 console where you can work with the database e.g. querying like:

`select ltg.label, lt.label from tags t join localized_tags lt on lt.tag = t.id join tag_groups tg on tg.id = t.tag_group join localized_tag_groups ltg on ltg.tag_group = tg.id where ltg.lang = "en" and lt.lang = "en";`