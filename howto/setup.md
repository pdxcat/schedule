Setup
=====

Database
--------

To create a new instance of the schedule database, you should be able to
run `cat schema/*.sql | mysql $dbname`. You will need to populate the
`ns_desk` and, optionally, the `ns_cat_group` and `ns_cat_type` tables.

Web app
-------

1. Copy `db.EXAMPLE.inc` to `db.inc` and add your database settings and
   credentials.
2. Point your web server at the public_html directory.
3. Tinker with the .htaccess files as appropriate.

Deskbot
-------

1. Edit the deskbot ruby script to include your database settings and
   credentials.
2. Edit the deskbot ruby script to include your irc settings.
3. Run the script.
