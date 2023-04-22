
# History of taginfo

Here are some of the more important events in the history of the taginfo
project. The numerous small improvements and bugfixes can't all be listed.

## October 2010

* Project started

## November 2010

* Added localization support, first languages English, German, Italian
* Add support for embedding taginfo snippets into OSM wiki
* Add the first reports

## March 2011

* Started API documentation

## April 2011

* Added JSONP support
* taginfo.openstreetmap.ie is the first site other than the main site
  to use taginfo.

## June 2011

* Switched from taginfo.openstreetmap.de to taginfo.openstreetmap.org

## October 2011

* Add French and Russian localization
* Add maps for keys on ways
* Add config file

## January 2012

* New design for web user interace

## July 2012

* Add support for Ruby 1.9

## November 2012

* Add Polish localization

## December 2012

* Add CORS support

## January 2013

* Switch to API version 4
* Fully switch to Ruby 1.9, doesn't work with Ruby 1.8 any more
* Switch to jQuery 1.9
* Switch from Protovis to D3 for graphs and charts
* Add word cloud to homepage
* Add support for relation types
* Add support for keyboard shortcuts
* Add support for key/tag/relation type thumbnails from wiki
* Start collecting some statistics in a database thats kept from day to day

## February 2013

* Add link to Overpass Turbo

## February 2014

* Main taginfo site moves to OSMF infrastructure

## March 2014

* Add Portuguese localization

## April 2014

* Added Ukrainian localization

## May 2014

* Add support for key/tag comparison
* Add Level0 editor link
* Add support for maps on popular tags
* Remove support for old API versions 2 and 3
* Add Hungarian, Spanish, and Vietnamese localization

## September 2014

* Add support for external projects

## November 2014

* Add Brazilian Portuguese localization

## February 2015

* Add 'Similarity' tab for keys
* Add 'Historic development' report

## March 2015

* Add Japanese localization
* Add 'Wiki images' report

## August 2015

* Add 'taglist' feature

## November 2015

* Database statistics creation code switches from old osmium to new libosmium

## December 2015

* Major refactoring of the shell scripts collecting the source data making the
  code cleaner and more robust

## January 2016

* New web site layout with more prominent menu and better mobile support

## February 2016

* Cleanup of database statistics creation code with some speedups

## August 2016

* Support for HiDPI displays in web UI
* Add Taiwanese Chinese localization
* Better integration of projects

## August 2020

* Moved C++ binaries into their own repository taginfo-tools. Generating
  the statistics is much faster now due to use of hash containers from the
  Abseil library.

## October 2020

* For some tags such as `wikipedia`, `website`, `url`, `wikidata`, `phone`,
  etc. links to relevant websites are now shown on the tags overview tab.
* Full text search is now much faster, sometimes time goes down from minutes
  to "instant".
* Now shows approval status in wiki tab of key and tag pages.

## November 2020

* Added 'Chronology' tab for keys and tags showing development of keys/tags
  over time. This works for all keys and the more popular tags.
* Improved support for mobile: Tool links are now also available on smaller
  screens.

## December 2021

* Add "characters" tab to key/tag/relation pages showing a table with all
  Unicode characters used in the key/tag/relation.

## October 2022

* Started using Rubocop to help cleaning up Ruby code.
* Started to add some code making running a multi-instance version of taginfo
  easier.

## March/April 2023

* Large refactoring of the CSS and Javascript. Removed dependency on jQuery
  and several other Javascript libraries and modernized the Javascript code.
  Use modern CSS functionality like flex and grid layouts.
* A lot of the site works better with smaller screens now though much work
  remains.

