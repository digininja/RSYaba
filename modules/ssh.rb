#!/usr/bin/env ruby

require 'net/ssh'
require 'modules/brute.rb'

class Brute_ssh < Brute
	@@port = 22

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
			Net::SSH.start(@@host, @username, :auth_methods => "password", :timeout => 60, :password => @password, :verbose => Logger::FATAL) do |ssh|
				puts "Success with " + @username + " " + @password
				if @@verbose
					# capture all stderr and stdout output from a remote process
					output = ssh.exec!("hostname")
					puts "Host: " + output
				end
				# connection is explicitly closed when this block closes so no need
				# for a close call
				@success = true
			end
		rescue SocketError
			puts "Can't connect to the host"
			exit
		rescue Net::SSH::AuthenticationFailed
			puts "Failure with " + @username + " " + @password if @@verbose
		rescue Errno::ECONNREFUSED
			puts "Can't find running SSH server"
			exit
		rescue Net::SSH::Disconnect
			raise ThrottleBackException
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
		puts"
Usage for ssh module

Usage: rsyaba.rb [OPTION] ... ssh
	--help, -?: show help
	--host, -h: host
	--wordlist x, -w x: the wordlist to use, either a file or - for STDIN
	--userlist x, -u x: a file containing the list of users
	--user x, -U x: a single username
	--throttle x, -T x: throttle back time, see SSH README for more information
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
