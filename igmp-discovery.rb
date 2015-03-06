#!/usr/bin/env ruby
#
# igmp-discovery.rb
#
# Author: Matteo Cerutti <matteo.cerutti@hotmail.co.uk>
#

require 'rubygems'
require 'snmp'
require 'socket'
require 'optparse'
include SNMP

options = {}
optparse = OptionParser.new do |opts|
  opts.banner += " <host>"

  options[:community] = "public"
  opts.on("-c", "--community <COMMUNITY>", String, "SNMP community") do |community|
    options[:community] = community
  end

  options[:version] = :SNMPv2c
  opts.on("-v", "--version <SNMPv1|SNMPv2c>", String, "SNMP version") do |version|
    options[:version] = version
  end

  options[:config] = File.dirname(__FILE__) + "/igmp-discovery.yaml"
  opts.on("--config <CONFIG>", "Path to configuration file") do |config|
    options[:config] = config
  end

  options[:ns_lookup] = false
  opts.on("--ns-lookup", "Perform NS lookup") do
    options[:ns_lookup] = true
  end
end

begin
  optparse.parse!

  raise("Must specify SNMP target host") unless ARGV.length > 0
  host = ARGV.first
end

begin
  config = ::YAML.load_file(options[:config])
rescue Exception => e
  STDERR.puts("Caught exception in loading configuration file: #{e.message}")
  exit 1
end

sysdescr = nil

interfaces = {}
SNMP::Manager.open(:host => host, :version => options[:version], :community => options[:community]) do |manager|
  # identify device first
  resp = manager.get(["sysDescr.0"])
  resp.each_varbind do |varbind|
    sysdescr = varbind.value.to_s
  end

  manager.walk(["ifDescr", "ifAlias"]) do |row|
    row.each do |varbind|
      # extract interface index from var name
      index = varbind.name.to_s.split('.').last
      if interfaces[index].nil?
        interfaces[index] = {}
        interfaces[index][:igmp_reporters] = {}
      end

      case varbind.name.to_s
        when /ifDescr/
          var = 'name'
          interfaces[index][:name] = varbind.value.to_s

        when /ifAlias/
          interfaces[index][:description] = varbind.value.to_s

        else
          STDERR.puts("Unexpected SNMP entry (#{varbind.inspect})")
      end
    end
  end

  objectid = nil
  config["objectids"]["igmp_cache_last_reporter"].each do |k, v|
    if sysdescr =~ Regexp.new(v["sysdescr"])
      objectid = v["oid"]
      break
    end
  end
  objectid ||= "igmpCacheLastReporter"

  igmpCacheLastReporter = ObjectId.new(objectid)
  manager.walk(igmpCacheLastReporter) do |row|
    row.each do |varbind|
      oid = varbind.name.to_s.split('.')
      index = oid.last
      group = oid[(oid.size - 5) .. (oid.size - 2)].join('.')

      # store information in the interfaces hash
      ip = varbind.value.to_s
      interfaces[index][:igmp_reporters][ip] ||= []
      interfaces[index][:igmp_reporters][ip] << group unless interfaces[index][:igmp_reporters][ip].include?(group)
    end
  end
end

puts "IGMP subscriptions discovered on #{host} @ #{Time.now}"
puts "----------------"

count = 0
interfaces.each do |index, interface|
  if interface[:igmp_reporters].size > 0
    puts if count > 0
    puts "Interface: #{interface[:name]} (#{interface[:description]})"
    puts "IGMP reporters:"
    interface[:igmp_reporters].each do |reporter, groups|
      puts "  #{reporter}#{options[:ns_lookup] ? ' (' + Socket.gethostbyaddr(reporter.split('.').map { |i| i.to_i }.pack('CCCC')).first + ')' : ''}"
      groups.each do |group|
        puts "    - #{group}"
      end
    end
    count += 1
  end
end
