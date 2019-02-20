#!/usr/bin/env ruby
# Laurent Martin/Aspera 2016

require 'rubygems'
require 'logger'
require 'yaml'
require 'pp'
require 'fileutils'

# constants
FASPEX_ENV_PREFIX='faspex_'
FASPEX_INTERNAL_META_PREFIX='_metadata_'
FASPEX_USER_META_PREFIX='faspex_meta_'
FASPEX_DROPBOX='_dropbox_name'
PKG_META=:meta

# get config file as argument, or deduce from this script path
case ARGV.length
when 0
  config_file = File.expand_path(__FILE__).gsub(/\.rb$/,'.yaml')
when 1
  config_file = ARGV.first
else
  raise "0 or 1 argument is expected"
end
puts "using config file: #{config_file}"
$config=YAML.load_file(config_file)

# prepare log
$logger = case $config['logger']
when nil
  Logger.new(File.expand_path(__FILE__).gsub(/\.rb$/,'.log'))
when 'stdout'
  Logger.new(STDOUT)
when 'syslog'
  Logger::Syslog.new("as_cli")
else
  Logger.new($config['logger'])
end
$logger.level = $config['loglevel'].to_i rescue 1
$logger.info("Started")

# read package information from env vars
def get_package_data
  pkg_data={PKG_META=>{}}
  # get faspex env vars
  ENV.keys.sort.select{|n| n.start_with?(FASPEX_ENV_PREFIX)}.each {|n| pkg_data[n.split(/^#{FASPEX_ENV_PREFIX}/).last]=ENV[n]}
  ENV.keys.sort.select{|n| n.start_with?(FASPEX_INTERNAL_META_PREFIX)}.each {|n| pkg_data[PKG_META]['_'+n.split(/^#{FASPEX_INTERNAL_META_PREFIX}/).last]=ENV[n]}
  pkg_data[PKG_META]['_dropbox_name']=ENV[FASPEX_DROPBOX] if (ENV.has_key?(FASPEX_DROPBOX))
  pkg_data[:meta_custom_list]=[]
  pkg_data['metadata_fields'].split(', ').each {|field|
    envvar=field.gsub(/ /, "_").gsub(/[^[:alnum:]_]/, '').downcase
    if ! field.start_with?('_') then
      envvar=FASPEX_USER_META_PREFIX+envvar
      pkg_data[:meta_custom_list].push(field)
    end
    pkg_data[PKG_META][field]=ENV[envvar];
  } if pkg_data.has_key?('metadata_fields')
  pkg_data.delete('metadata_fields')
  pkg_data['recipient_list']=pkg_data['recipient_list'].split(', ') if pkg_data.has_key?('recipient_list')
  if (pkg_data.has_key?('recipient_count')) then
    pkg_data['recipient_list2']=[]
    (0..pkg_data['recipient_count'].to_i.pred).each {|index| name='recipient_'+index.to_s;pkg_data['recipient_list2'].push(pkg_data[name]);pkg_data.delete(name)}
    pkg_data.delete('recipient_count')
  end
  return pkg_data
end

# execute specific actions
def process_move(pkg_data,subfolder)
  $logger.debug("moveto=#{subfolder}")
  source_folder=File.join($config['docroot'],pkg_data['pkg_directory'])
  destination_folder=File.join($config['workflow_folder'],subfolder)
  FileUtils.mkdir_p(destination_folder)
  message=''
  # loop on all files (and folders) in package
  Dir.glob(File.join(source_folder,'*')).each {|origfullpath|
    # keep same name if it does not exist at destination
    filename=File.basename(origfullpath)
    destfullpath=File.join(destination_folder,filename)
    # else find version number
    while File.exist?(destfullpath) do
      file_version=file_version.nil? ? 1 : file_version.next
      destfullpath=File.join(destination_folder,File.basename(filename,'.*')+".#{file_version}"+File.extname(filename))
    end
    $logger.debug("#{origfullpath} -> #{destfullpath}")
    FileUtils.mv(origfullpath,destfullpath)
    message=message+" #{filename} -> #{File.basename(destfullpath)}\n"
    #File.symlink(origfullpath,destfullpath) rescue nil
  }
  File.open(File.join(source_folder,'_FILES_HAVE_BEEN_MOVED_.txt'),"w") {|file| file.write("The following files were moved to: #{destination_folder}\n#{message}")} if !message.empty?
end

# main procedure
begin
  pkg_data=get_package_data
  $logger.debug("package_data=#{PP.pp(pkg_data,'').chomp}")
  moveto=nil
  pkg_data[:meta_custom_list].each {|field|
    # find action in value of metadata
    actionmatch=pkg_data[PKG_META][field].match(/\(M:([^\)]+)\)/)
    if !actionmatch.nil? then
      folder=actionmatch[1]
      $logger.debug("folder=#{folder}")
      if moveto.nil? then
        moveto=folder
      else
        moveto=File.join(moveto,folder)
      end
    end
  }
  if !moveto.nil? then
    process_move(pkg_data,moveto)
  else
    $logger.info("No action")
  end
rescue => e
  $logger.error("an error occured: #{e}")
  raise e
end
$logger.info("Finished")
