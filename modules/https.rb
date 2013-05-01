#!/usr/bin/env ruby
require 'net/https'
require 'uri'
require 'modules/brute.rb'
require 'modules/http.rb'

class Brute_https < Brute_http
	@@port = 443
	@@protocol = "https"
end
