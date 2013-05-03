#!/usr/bin/env ruby
# encoding: UTF-8

# ==
#
# rsyaba - RS Yet Another Brute Attacker
#
# Yaba is tool to run brute force attacks against various services in a similar
# way to Hydra and Medusa. I started writing it as I found both had troubles with
# HTTP and getting SSH to work was fiddly so I though why not write my own.
#
# == Usage
#
# To get basic help simply run
#
# ./rsyaba.rb --help
#
# To list all supported protocols
#
# ./rsyaba.rb --list_protocols
#
# To get help on a specific protocol
#
# ./rsyaba.rb http --help
#
# To run an attack with words from the 100_words.txt file and usernames from user_list
#
# ./rsyaba.rb http --host www.example.com --path /login.php --wordlist 100_words.txt -u user_list
#
# To do the attack taking the word list from stdin using rsmangler to generate the
# list. A single username, robin
#
# rsmangler.rb -f names | ./rsyaba.rb ssh --wordlist - -U robin --host example.com
#
# To do a HTTPS attack against a CSRF protected site knowing the token is stored
# in the field token and that on a successful login the word "Success" is
# displayed on the screen
#
# ./rsyaba.rb https --host www.example.com --path /login/with_token.php -w 100_words.txt  --success_message="Success" --token_field="token" -U robin
#
#
# Author:: Robin Wood (robin@digininja.org)
# Copyright:: Copyright (c) Robin Wood 2010
# Licence:: GPL
#
require 'rubygems'
require 'getoptlong'

THROTTLE_BACK_DELAY = 0.4
MAX_THREADS         = 5
YABA_VERSION        = 'rsyaba 1.0.1, Robin Wood (robin.wood@randomstorm.com) (www.randomstorm.com)'

class ThrottleBackException < RuntimeError
end

class TryAgainException < RuntimeError
end

class MissingParameterException < RuntimeError
end

def to_class(name)
  Kernel.const_get(name)
end

def get_protocols
  modules = []
  Dir.foreach('./modules') do |file|
    if /(.*)\.rb/.match(file)
      module_script = $1
      # Ignore the base class
      next if module_script == 'brute'
      modules << $1
    end
  end
  modules.sort!
  return modules
end

def list_protocols
  puts 'The available protocols are:'
  puts

  modules = get_protocols
  modules.each { |mod| puts mod }
  exit
end

def usage
  puts YABA_VERSION
  puts '
Usage:
  yaya.rb <protocol> --help:  Get help for the specified protocol
  yaya.rb --list_protocols, -l: show basic help
  yaya.rb --help, -?: show basic help

'
  exit
end

def is_numeric(s)
  begin
    Float(s)
  rescue
    false # not numeric
  else
    true # numeric
  end
end

def random_password
  return (0...8).map { 65.+(rand(25)).chr }.join
end

wordlist_fh    = nil
max_threads    = MAX_THREADS
verbose        = false
port           = nil
throttle_delay = THROTTLE_BACK_DELAY

usage if ARGV.length < 1

protocol = ARGV[0]

case protocol
when '-?'
  usage
when '--help'
  usage
when '-l'
  list_protocols
when '--list_protocols'
  list_protocols
end

base_class = nil
protocols  = get_protocols

if protocols.include? protocol
  require 'modules/' + protocol + '.rb'

  base_class_name = 'Brute_' + protocol
  base_class = to_class base_class_name
else
  puts 'Unknown module'
  exit
end

opts_arr = [
  ['--help', '-?', GetoptLong::NO_ARGUMENT],
  ['--host', '-h' , GetoptLong::REQUIRED_ARGUMENT],
  ['--wordlist', '-w' , GetoptLong::REQUIRED_ARGUMENT],
  ['--userlist', '-u' , GetoptLong::REQUIRED_ARGUMENT],
  ['--user', '-U' , GetoptLong::REQUIRED_ARGUMENT],
  ['--throttle', '-T' , GetoptLong::REQUIRED_ARGUMENT],
  ['--max_threads', '-t' , GetoptLong::OPTIONAL_ARGUMENT],
  ['--list_protocols', '-l' , GetoptLong::NO_ARGUMENT],
  ['-v', GetoptLong::NO_ARGUMENT]
]

opts_arr += base_class.get_opts unless base_class.nil?

opts = GetoptLong.new(*opts_arr)

#doing this as the getoptlong.new burns up all the arguments so it can't be used again in the modules
stored_opts = []

host = nil

usernames = nil
begin
  opts.each do |opt, arg|
    case opt
    when '--userlist'
      unless File.exist?(arg)
        puts 'User list file not found'
        puts
        exit
      end
      usernames = {}
      userlist_fh = File.open arg, 'r'
      until userlist_fh.eof?
        user = userlist_fh.gets.chomp
        usernames[user] = false
      end
      userlist_fh.close
    when '--user'
      usernames = {arg => false}
    when '--port'
      if is_numeric(arg)
        port = arg.to_i
        base_class.set_port(arg.to_i) unless base_class.nil?
      else
        puts 'Invalid port passed'
        puts
        exit
      end
    when '--list_protocols'
      list_protocols
    when '--help'
      if base_class.nil?
        usage
      else
        base_class.usage
      end
    when '--host'
      base_class.set_host(arg) unless base_class.nil?
      host = arg
    when '--throttle'
      if is_numeric arg
        throttle_delay = arg.to_i
      else
        puts 'Invalid throttle time, using ' + THROTTLE_BACK_DELAY.to_s
      end
    when '--max_threads'
      if is_numeric arg
        max_threads = arg.to_i
      else
        puts 'Invalid number specified for max threads, using ' + MAX_THREADS.to_s
      end
    when '--wordlist'
      if arg == '-'
        wordlist_fh = STDIN
      else
        begin
          if File.exist? arg
            wordlist_fh = File.new(arg, 'r')
          else
            puts 'Word list file not found'
            puts
            exit
          end
        rescue
          puts 'There was a problem opening the worlist file'
          exit
        end
      end
    when '-v'
      verbose = true
      base_class.set_verbose unless base_class.nil?
    else
      stored_opts << [opt, arg]
    end
  end
rescue GetoptLong::MissingArgument, GetoptLong::InvalidOption, MissingParameterException
  puts
  if base_class.nil?
    usage
  else
    base_class.usage
  end
rescue => e
  puts 'Something failed'
  puts e.inspect
  exit
end

if host.nil?
  puts 'Host not specified'
  puts

  if base_class.nil?
    self.usage
  else
    base_class.usage
  end
end

exit if base_class.nil?

base_class.parse_params stored_opts

# If no usernames passed then there isn't a username to test so pass nil in instead
if usernames.nil?
  usernames = {}
  usernames[nil] = false
end

if wordlist_fh.nil?
  puts 'You must specify a wordlist file, for STDIN use -'
  puts
  exit
end

if base_class.get_host.nil?
  puts 'You didn\'t provide a hostname'
  exit
end

threads          = []
$running_threads = 0
sleep_delay      = 0
retries          = []

until wordlist_fh.eof?
  password = wordlist_fh.gets.chomp

  usernames.each_pair do |username, succ|
  #  puts 'Testing username ' + username + ' ' + ' with password ' + password

    sleep sleep_delay
    while $running_threads >= max_threads
      #do nothing
    end

    next if usernames[username]

    b = base_class.new
    b.username = username
    b.password = password

    a = Thread.new do
      begin
        usernames[username] = true if b.login
      rescue MissingParameterException
        puts
        puts 'A key parameter was missing'
        exit
      rescue ThrottleBackException
        sleep_delay += throttle_delay
        puts 'push ' + username + ' and ' + password + ' back into the stack to try again' if verbose
        retries << b
        #retries << {'password' => password, 'user' => username}
        $running_threads -= 1
      rescue => fault
        puts 'Something failed'
      #  puts fault.inspect
      #  puts fault.backtrace
        exit
      end
    end

#    puts 'sleep delay = ' + sleep_delay.to_s
    $running_threads += 1
    threads << a

  end
end

wordlist_fh.close

if retries.length > 0
  puts 'Finished first run through, retrying failed attempts'

  retries.each do |b|
  #  puts 'Testing username ' + username + ' ' + ' with password ' + password

    sleep sleep_delay
    while $running_threads >= max_threads
      #do nothing
    end

    next if usernames[b.username]

    a = Thread.new do
      begin
        usernames[b.username] = true if b.login
      rescue MissingParameterException
        puts
        puts 'A key parameter was missing'
        exit
      rescue ThrottleBackException
        sleep_delay += throttle_delay
        puts 'This pair failed for a second time, giving up on it ' + b.username + ' and ' + b.password + '' if verbose
        $running_threads -= 1
      rescue => fault
        puts 'Something failed'
      #  puts fault.inspect
      #  puts fault.backtrace
        exit
      end
    end

    $running_threads += 1
    threads << a
  end
end

threads.each { |x| x.join }
