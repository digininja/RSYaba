#!/usr/bin/env ruby
require 'getoptlong'

class Brute
  @@verbose = false
  @@host = nil
  attr_accessor :verbose

  def self.set_verbose
    @@verbose=true
  end

  def self.get_host
    return @@host
  end

  def self.set_host host
    @@host=host
  end

  def dump_details
    puts "host: " + @@host
  end

  def login
    puts "no login code written"
    return true
  end

  # return blank opts
  def self.get_opts
    return [
    ]

  end

  # there are no parameters to parse
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
