# Taginfo

Brings together information about OpenStreetMap tags and makes it searchable
and browsable.

**Documentation:** See the
[Taginfo](https://wiki.openstreetmap.org/wiki/Taginfo) page at the OpenStreetMap
wiki.

**Live System:** [taginfo.openstreetmap.org](https://taginfo.openstreetmap.org/)


## Files

* `/sources`  - import scripts
* `/web`      - web user interface and API
* `/examples` - some misc example stuff
* `/tagstats` - C++ programs to create database statistics etc.


## Prerequisites

It uses:

* Ruby (must be at least 2.4)
* Mongrel or Apache2 mod_passenger
* [Sinatra web framework](http://www.sinatrarb.com/) and other ruby libraries
* curl binary
* sqlite3 binary
* Optional: Parallel bzip (pzbip2)

Install the Debian/Ubuntu packages:
```sh
$ sudo apt-get install curl sqlite3
$ sudo apt-get install ruby-passenger libapache2-mod-passenger
```

Install the Gems:
```sh
$ sudo gem install bundler
$ sudo bundle install
```

## Data Import

See [Taginfo/Installation](https://wiki.openstreetmap.org/wiki/Taginfo/Installation)
at OpenStreetMap's wiki.


## Web User Interface

You need a `/data` directory (in the parent directory of the directory where
this `README.md` is). It must contain the sqlite database files created in the
data import step or downloaded from page
[taginfo.openstreetmap.org/download](https://taginfo.openstreetmap.org/download).

To start the web user interface:
```sh
$ cd web
$ ./taginfo.rb
```

## Javascript

Taginfo uses the following Javascript libraries:
* jQuery 1.9.0
* jQuery UI 1.9.2
* [customSelect](http://adam.co/lab/jquery/customselect/)
* [tipsy](http://onehackoranother.com/projects/jquery/tipsy/)
* [jQuery Cookie](https://github.com/carhartl/jquery-cookie/)
* Flexigrid (from [Google Code](http://code.google.com/p/flexigrid/) and
  [flexigrid.info](http://www.flexigrid.info/), but with changes and bugfixes)
* [slicknav](http://slicknav.com/)

All the Javascript and CSS needed is already included.


## Thanks

To the [many people](https://github.com/taginfo/taginfo/graphs/contributors)
helping with bug reports, code and translations.


## Contact

There is a mailing list for developers and people running their own instances
of taginfo:
[taginfo-dev](https://lists.openstreetmap.org/listinfo/taginfo-dev)


## Author

Jochen Topf (jochen@topf.org) - https://jochentopf.com/

