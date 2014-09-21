Taginfo
=======

Brings together information about OpenStreetMap tags and makes it searchable and browsable.

&nbsp;&nbsp;**Documentation:** the page [Taginfo](http://wiki.openstreetmap.org/wiki/Taginfo) at OpenStreetMap's wiki

&nbsp;&nbsp;**Live System:** [taginfo.openstreetmap.org](http://taginfo.openstreetmap.org/)


Files
-----

* `/sources`  - import scripts
* `/web`      - web user interface and API
* `/examples` - some misc example stuff
* `/tagstats` - C++ program to create database statistics


Prerequisites
-------------

It uses:

* Ruby (must be at least 1.9.1)
* Mongrel or Apache2 mod_passenger
* [Sinatra web framework](http://www.sinatrarb.com/)
* Rack Contrib Gem (for `Rack::JSONP`)
* JSON gem (install with gem, Debian/Ubuntu packages are too old and buggy)
* curl binary
* sqlite3 binary and ruby libs
* m4 binary

Install the Debian/Ubuntu packages:
```bash
$ sudo apt-get install curl m4 sqlite3 ruby-sqlite3 ruby-passenger libapache2-mod-passenger
```

Install the Gems:
```bash
$ sudo gem install rack rack-contrib sinatra sinatra-r18n json
```

There is a developer mailing list: [taginfo-dev](http://lists.openstreetmap.org/listinfo/taginfo-dev)


Data Import
-----------

See [Taginfo/Running](http://wiki.openstreetmap.org/wiki/Taginfo/Running) at OpenStreetMap's wiki.


Web User Interface
------------------

You need a `/data` directory (where this `README.md` is). It must contain the sqlite database files created in the data import step or downloaded from page [taginfo.openstreetmap.org/download](http://taginfo.openstreetmap.org/download).

To start the web user interface:
```bash
$ cd web
$ ./taginfo.rb
```

Javascript
----------

Taginfo uses the following Javascript libraries:
* jQuery 1.9.0
* jQuery UI 1.9.2
* [customSelect](http://adam.co/lab/jquery/customselect/)
* [tipsy](http://onehackoranother.com/projects/jquery/tipsy/)
* [jQuery Cookie](https://github.com/carhartl/jquery-cookie/)
* Flexigrid (from [Google Code](http://code.google.com/p/flexigrid/) and [flexigrid.info](http://www.flexigrid.info/), but with changes and bugfixes)

All the Javascript and CSS needed is already included.


Thanks
------

* Stefano Tampieri, for the Italian translation
* Ilya Zverev <<zverik@textual.ru>>, for the Russion translation
* Jocelyn Jaubert <<jocelyn.jaubert@gmail.com>>, for the French translation
* Jacek Buczyński <<jacekzlodzi@gmail.com>>, for the Polish translation


Author
------

Jochen Topf <<jochen@remote.org>> AKA [Joto](http://wiki.openstreetmap.org/wiki/User:Joto)
