Send new events :

    $metalive_url = http://metalive.tryphon.eu:8080
    curl -X POST -d '{"description": {"title": "Yellow submarine", "artist": "The Beatles", "group": "MUSIC", "album": "Yellow submarine" } }' $metalive_url
    curl -X POST -d '{"description": {"title": "Foxy Lady", "artist": "Jimi Hendrix", "group": "MUSIC", "album": "Are You Experienced" } }' $metalive_url

Install/update :

    $ rsync -av --cvs-exclude . radio.dbx1.tryphon.priv:/var/www/tryphon.eu/metalive/
    $ ssh radio.dbx1.tryphon.priv
    radio$ cd /var/www/tryphon.eu/metalive
    radio$ bundle install --deployment --path vendor/bundle
    radio$ mysql metalive < create_db.sql
    radio$ sudo -u nobody bundle exec ruby ./lib/metalive/server.rb
