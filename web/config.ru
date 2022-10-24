#
#  For use with Phusion Passenger
#

Encoding.default_external = 'UTF-8'

require 'sinatra'
require './taginfo'
require 'json'
require 'lib/config'

set :run, false
set :environment, :production

logdir = TaginfoConfig.new(File.expand_path(File.dirname(__FILE__)) + '/../../taginfo-config.json').get('logging.directory')

if logdir.to_s != ''
    today = Time.now.strftime('%Y-%m-%d')
    log = File.new("#{logdir}/taginfo-#{ today }.log", 'a')
    log.sync = true

    $stderr.reopen(log)

    $stderr.puts "Taginfo started #{Time.now}"

    $queries_log = File.new("#{logdir}/queries-#{ today }.log", 'a')
    $queries_log.sync = true
end

run Taginfo

