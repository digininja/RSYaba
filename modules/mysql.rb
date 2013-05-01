#!/usr/bin/env ruby
require 'mysql'
require 'modules/brute.rb'

class Brute_mysql < Brute
	@@port = 3306

	attr_accessor :username, :password
	attr_reader :success

	def initialize
		@success = false
	end

	def login
		if @username.nil?
			puts "No username specified"
			puts
			usage
		end

		if @username.nil? or @password.nil? or @@host.nil? or @@port.nil?
			Thread.abort_on_exception = true
			raise MissingParameterException.new, "Missing parameters"
		end

		if @@verbose
			puts "Starting with " + @username + " " + @password
		end

		begin
			# connect to the MySQL server
			dbh = Mysql.real_connect(@@host, @username, @password, "test", @@port)
			# get server version string and display it
			puts "Success with " + @username + " " + @password
			#puts "Server version: " + dbh.get_server_info
			@success = true
		rescue Mysql::Error => e
			if e.error =~ /Can't connect/
				puts "Could not connect to specified MySQL server"
				exit
			end
		#	puts e.inspect
		#	puts "Error code: #{e.errno}"
		#	puts "Error message: #{e.error}"
		#	puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
		ensure
			# disconnect from server
			dbh.close if dbh
		end
		$running_threads -= 1

		return @success
	end

	def dump_details
		puts "host: " + @@host
		puts "port: " + @@port.to_s
		puts "username: " + @username.to_s
		puts "password: " + @password.to_s
	end

	def self.usage
		puts YABA_VERSION
		puts "
Usage for MySQL module

Usage: rsyaba.rb [OPTION] ... mysql
	--help, -?: show help
	--host, -h: host
	--wordlist x, -w x: the wordlist to use, either a file or - for STDIN
	--userlist x, -u x: a file containing the list of users
	--user x, -U x: a single username
	--throttle x, -T x: throttleback time, see SSH README for more information
	--max_threads x, -t x: maximumn number of threads, more isn't always better, default 5
	--port, -p: Port number
	-v: verbose

"
		exit
	end

	def self.get_opts
		return [
		]

	end

	def self.parse_params opts
		begin
			opts.each do |opt, arg|
				# Nothing to do
			end
		rescue => e
			puts e
			usage
		end
	end
end
