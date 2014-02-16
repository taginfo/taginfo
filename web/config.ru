#
#  For use with Phusion Passenger
#

require 'sinatra'
require './taginfo.rb'
require 'json'
require 'lib/config.rb'

TaginfoConfig.read

LOGDIR=TaginfoConfig.get('logging.directory', '/osm/taginfo/var/log');
 
set :run, false
set :environment, :production

today = Time.now.strftime('%Y-%m-%d')
log = File.new("#{LOGDIR}/taginfo-#{ today }.log", "a")
log.sync = true

# https://github.com/joto/taginfo/issues/34
#$stdout.reopen(log)
$stderr.reopen(log)

$stderr.puts "Taginfo started #{Time.now}"

$queries_log = File.new("#{LOGDIR}/queries-#{ today }.log", "a")
$queries_log.sync = true

run Taginfo

