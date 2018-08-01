#!/usr/bin/env ruby

# this should be run before starting solr for the first time in a dev/test
# environment
# it installs libraries and 

require 'net/http'
require 'fileutils'
require 'optparse'
require 'json'
require 'uri'

DEFAULTS = {
  name: 'trln-dev',
  solr_url: 'http://localhost:8983/solr/',
  conf_dir: 'solr-dir/solr6_test_conf',
  solr_dir: 'solr-dir/solr-6.3.0'
}.freeze

options = Marshal.load(Marshal.dump(DEFAULTS))

OptionParser.new do |opts|
  opts.banner = "Usage: solr_init.rb [options]"
  opts.on("-u", "--url URL", "Set Solr base URL") do |url|
    options[:solr_url] = url
  end

  opts.on("-c", "--core-dir COREDIR", "Location of core configuration directory", "(contains conf/ and lib/ directories)") do |dir|
    options[:conf_dir] = dir
  end

  opts.on("-s", "--solr SOLRDIR", "Path to Solr installation") do |dir|
    options[:solr_dir] = dir
  end

  opts.on('-n', '--name NAME',"Name of collection (trln-dev)") do |name|
    options[:name] = name
  end

  opts.on('-C', '--clean', "Reset Solr (delete collection)") do 
    options[:clean] = true
  end
end.parse!

def check_solr_install?(options)
  base = options[:solr_dir]
  File.directory?(base) and File.exists?(File.join(base, "bin/solr"))
end

def check_solr_conf?(options)
  base = options[:conf_dir]
  unless File.directory?(base)
    parent=File.dirname(base)
    FileUtils.mkdir_p(parent) unless File.directory?(parent)
    puts "Cloning solr configuration from github"
    Dir.chdir(parent) do
      output=%x(git clone https://github.com/trln/solr6_test_conf solr6_test_conf)
      raise "Unable to clone repository: #{output}" unless $?.exitstatus == 0
    end
  end

   File.directory?(base) and File.directory?(File.join(base, 'lib')) and File.directory?(File.join(base, "test_core/conf"))
end

check_solr_install?(options) or raise "Solr not found in #{options[:solr_dir]}"

check_solr_conf?(options) or raise "Core configuration not found in #{options[:conf_dir]}"

# Compute the rest of the options
options[:solr_bin] = 'bin/solr' # we will chdir to solr_dir before running!
options[:solr_home] = File.join(options[:solr_dir], 'server/solr')
options[:lib_dir_src] = File.join(options[:conf_dir], "lib")
options[:lib_dir_dest] = File.join(options[:solr_home], 'lib')
options[:collection_conf_dir] = File.join(options[:conf_dir], "test_core")

def solr_running?(options={})
  bin = options[:solr_bin]
  Dir.chdir(options[:solr_dir]) do
    output = %x(#{bin} status)
    return $?.exitstatus == 0
  end
end

def ensure_stopped(options)
  rv = true
  if solr_running?(options)
    bin = options[:solr_bin]
    Dir.chdir(options[:solr_dir]) do 
      output=%x(#{bin} stop)
      rv = $?.exitstatus == 0
      puts output unless rv
    end
  end
  rv
end

def start(options={})
  bin = options[:solr_bin]
  rv = false
   Dir.chdir(options[:solr_dir]) do 
    output=%x(#{bin} start -c)
    rv = $?.exitstatus == 0
    puts output unless rv
    rv
  end
  rv
end
  
def ensure_libdir(options={})
  libdir=options[:lib_dir_dest] or raise "Hey, I need options to be set"
  if not File.directory?(libdir)
    FileUtils.mkdir_p(libdir)
  end
end

def copy_jars(options={})
  libdir=options[:lib_dir_dest]
  Dir.glob(File.join(options[:lib_dir_src], '*jar')).each do |jar|
    target=File.join(libdir, File.basename(jar))
    if not File.exist?(target)
      puts "Installing #{File.basename(jar)}"
      FileUtils.copy(jar, target)
    end
  end
end

def collection_exists?(options={})
  uri=URI.join(options[:solr_url],"admin/collections?action=list&wt=json")
  response = Net::HTTP.get_response(uri)
  result = JSON.parse(response.body)
  result['collections'].include?(options[:name])
end
  
def create_collection(options={})
  bin=options[:solr_bin]
  rv = false
  core_dir = File.absolute_path(options[:collection_conf_dir])
  Dir.chdir(options[:solr_dir]) do
    output = %x(#{bin} create_collection -c #{options[:name]} -d #{core_dir})
    rv = $?.exitstatus == 0
    puts output unless rv
  end
  rv
end

def clean(options={})
  raise "Need options!" unless options[:clean]
  puts "Clearing out old configuration"
  if not solr_running?(options)
    print "\tStarting solr ... "
    start(options) or raise "Couldn't start!"
    puts "OK"
  end
  if collection_exists?(options)
    print "\tdeleting #{options[:name]} ... "
    Dir.chdir(options[:solr_dir]) do
      output=%x(bin/solr delete -c #{options[:name]})
      raise "Unable to delete collection #{options[:name]}: #{output}" unless $?.exitstatus == 0
    end
    puts "OK"
  else 
    puts "\t#{options[:name]} core not found."
  end
  print "\tstopping solr ... "
  ensure_stopped(options) or raise "Could not stop solr!"
  puts "OK"
  libs = options[:lib_dir_dest]
  if File.directory?(libs)
    print "\yremoving #{libs} ... "
    FileUtils.rm_rf(libs)
    puts "OK"
  end
  exit 0
end

clean(options) if options[:clean]
print "Making sure Solr is stopped ... "
x = ensure_stopped(options) or raise "Cannot ensure solr is stoppedi <<#{x}>>."
puts "OK"
ensure_libdir(options)
copy_jars(options)
print "Starting solr ... "
start(options) or raise "Cannot start solr!"
puts "OK"
if collection_exists?(options)
  puts "'#{options[:name]}' collection exists"
else 
  print "Creating collection #{options[:name]} ... "
  create_collection(options) or raise "Could not create collection"
  puts "OK"
end
puts "Solr is running and ready for indexing"
