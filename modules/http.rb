#!/usr/bin/env ruby
require 'net/https'
require 'uri'
require 'modules/brute.rb'
require "hpricot"

class Brute_http < Brute
	@@port = 80
	@@path = "/"
	@@get_cookie = false
	@@token_field = nil
	@@ua = "Yaba"
	@@referrer = "http://example.com"
	@@username_field = "username"
	@@password_field = "password"
	@@protocol = "http"
	@@success_message = "Success"
	@@failure_message = nil

	@cookie = nil
	@token = nil

	attr_accessor :username, :password
	attr_reader :success

	def initialize
		@cookie = nil
		@token = nil
		@success = false
	end

	def login
		if @@password_field.nil? or @@host.nil? or @@path.nil? or @@port.nil?
			Thread.abort_on_exception = true
			raise MissingParameterException.new, "Missing parameters"
		end

		begin
			if @@verbose
				if @username.nil?
					puts "Starting with " + @password
				else
					puts "Starting with " + @username + " " + @password
				end
			end

			http = Net::HTTP.new(@@host, @@port)

			if @@protocol == "https"
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			else
				# non-secure
			end

			headers = {
				'User-Agent' => @@ua
			}
			headers['Referrer'] = @@referrer unless @@referrer.nil?

			if !@@token_field.nil? or @@get_cookie
				# GET request -> so the host can set his cookies
				begin
					resp = http.get(@@path, nil)
				rescue NoMethodError => fault
					puts "A connection to the website couldn't be made, is it up?"
					exit
				end
				
				@cookie = resp.response['set-cookie']

				if !@@token_field.nil?
					doc = Hpricot(resp.body)
					(doc/"form//input").each do |row|
						row.attributes.to_hash.each_pair { |key, value|
							if key == "name" and value == @@token_field
								@token = row.attributes.to_hash["value"] if row.attributes.to_hash.has_key?("value")
								if @@verbose
									puts "Token found " + @token
								end
							end
						}
							
						#puts row.innerHTML.split(' ')[1] if td_item.attributes['class'] == 'price'
					end
				end

			end
			headers ["Cookie"] = @cookie if !@cookie.nil?

			if @username.nil?
				data = @@password_field + "=" + @password
			else
				data = @@username_field + "=" + @username + "&" + @@password_field + "=" + @password
			end

			if !@token.nil?
				data += "&" + @@token_field + "=" + @token
			end

			begin
				res = http.request_post(@@path, data, headers)
			rescue Errno::ECONNREFUSED =>fred
				puts "A connection to the website couldn't be made, is it up?"
				puts
				exit
			rescue NoMethodError => fault
				puts "A connection to the website couldn't be made, is it up?"
				puts
				exit
			end

			#puts res.body

			case res
				when Net::HTTPRedirection
					# need to put code in here to handle redirects but when redirecting off to a different host
					# this becomes really trick as it means recreating the HTTP object and repopulating it
					# then running through the whole process again. And this has to be recursive till you finally
					# get to an end point as you could get multiple redirects

					puts "Redirection occured - success occured - success?"
					if @username.nil?
						puts "Password used " + @password
					else
						puts "Password used " + @username + " " + @password
					end

					puts
					puts res.body
					puts
				when Net::HTTPSuccess
				  # OK
					if !@@success_message.nil?
						if (/#{@@success_message}/.match(res.body))
							if @username.nil?
								puts "Success with " + @password
							else
								puts "Success with " + @username + " " + @password
							end

				#			puts res.body
							if @get_cookie
								puts "The cookie is: " + @cookie.to_s
							end
							@success = true
						else
		#					puts "failed"
						end
						# failed
					else
						puts res.body
						puts @@failure_message
						exit
						if (/#{@@failure_message}/.match(res.body))
							puts "Failed with regex"
						else
							if @username.nil?
								puts "Success with " + @password
							else
								puts "Success with " + @username + " " + @password
							end
				#			puts res.body
							if @get_cookie
								puts "The cookie is: " + @cookie
							end
							@success = true
						end
					end
				else
					res.error!
			end
			$running_threads -= 1

			return @success
		rescue Net::HTTPServerException => detail
			puts "Page not found"
			puts
			exit
		rescue MissingParameterException => detail
			puts "Parameter not passed"
			puts
			exit
		end
	end

	def dump_details
		puts "http://" + @@host + @@path
		puts "on port " + @@port.to_s
	end

	def self.usage
		puts YABA_VERSION
		puts "
Usage for http module

Usage: rsyaba.rb [OPTION] ... http
	--help, -?: show help
	--host, -h: host
	--wordlist x, -w x: the wordlist to use, either a file or - for STDIN
	--userlist x, -u x: a file containing the list of users
	--user x, -U x: a single username
	--throttle x, -T x: throttleback time, see SSH README for more information
	--max_threads x, -t x: maximumn number of threads, more isn't always better, default 5
	--path, -P: path
	--ua x: user agent string to use
	--referrer x: set the referrer
	--get_cookie, -c: do a GET before the POST and use the returned session cookie in the POSt
	--port, -p: Port number
	--token_field: the name of a field containing a token that must be returned
	--username_field: the name of the username field, default = username
	--password_field: the name of the password field, default = password
	--success_message: the message received on success
	--failure_message: the message received on failure
	-v: verbose

"
		exit
	end

	def self.get_opts
		return [
			[ '--path', '-P', GetoptLong::REQUIRED_ARGUMENT ],
			[ '--get_cookie', '-c', GetoptLong::NO_ARGUMENT ],
			[ '--port', "-p" , GetoptLong::REQUIRED_ARGUMENT ],
			[ '--ua', GetoptLong::REQUIRED_ARGUMENT ],
			[ '--referrer', GetoptLong::REQUIRED_ARGUMENT ],
			[ '--token_field', GetoptLong::REQUIRED_ARGUMENT ],
			[ '--username_field', GetoptLong::REQUIRED_ARGUMENT ],
			[ '--password_field', GetoptLong::REQUIRED_ARGUMENT ],
			[ '--success_message', GetoptLong::REQUIRED_ARGUMENT ],
			[ '--failure_message', GetoptLong::REQUIRED_ARGUMENT ],
		]
	end

	def self.parse_params opts
		begin
			opts.each do |opt, arg|
				case opt
					when "--username_field"
						@@username_field = arg
					when "--password_field"
						@@password_field = arg
					when "--token_field"
						@@token_field = arg
					when "--path"
						@@path = arg
					when "--port"
						@@port = arg.to_i
					when "--get_cookie"
						@@get_cookie = true
					when "--referrer"
						@@referrer = arg
					when "--success_message"
						@@success_message = arg
						@@failure_message = nil
					when "--failure_message"
						@@success_message = nil
						@@failure_message = arg
					when "--ua"
						@@ua = arg
				end
			end
		rescue => e
			puts e
			self.usage
		end

		if @@path.nil?
			puts "You must specify a path"
			puts
			self.usage
		end

		if @@path !~ /^\//
			@@path = "/" + @@path
		end

	end

end
