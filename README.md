Send new events :

    $metalive_url = http://localhost:8080 # or http://metalive.tryphon.eu
    curl -X POST -d '{"description": {"title": "Yellow submarine", "artist": "The Beatles", "group": "MUSIC", "album": "Yellow submarine" } }' $metalive_url
    curl -X POST -d '{"description": {"title": "Foxy Lady", "artist": "Jimi Hendrix", "group": "MUSIC", "album": "Are You Experienced" } }' $metalive_url
