#
#  For use with Phusion Passenger
#

require 'sinatra'
require './taginfo.rb'
 
set :run, false
set :environment, :production

log = File.new("/osm/taginfo/log/taginfo.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)

run Taginfo

