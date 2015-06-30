#!/usr/bin/env ruby -Ku

# Mixpanel API Ruby Client Library
#
# URI related helpers
#
# Copyright (c) 2009+ Keolo Keagy
# See LICENSE for details
module Mixpanel
  # Utilities to assist generating and requesting URIs
  class URI
    def self.mixpanel(resource, params)
      base = Mixpanel::Client.base_uri_for_resource(resource)
      "#{File.join([base, resource.to_s])}?#{encode(params)}"
    end

    def self.encode(params)
      params.map { |key, val| "#{key}=#{CGI.escape(val.to_s)}" }.sort.join('&')
    end

    def self.download(uri, directory, file_name)
      uri      = URI(uri)
      use_ssl  = uri.scheme == 'https'
      directory = FileUtils.mkdir_p directory
      file      = "#{directory.first}/#{file_name}.json"

      begin
        Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl) do |http|
          request   = Net::HTTP::Get.new(uri)
          file_size = 10000000000

          http.request(request) do |response|
            open file, 'w' do |io|
              response.read_body do |chunk|
                if file_size <= 0
                  raise Mixpanel::URI::FinishError
                else
                  io.write chunk
                  file_size -= chunk.size
                end
              end

              io.flush
            end
          end
        end
      rescue Net::HTTPError => error
        raise HTTPError, JSON.parse(error.io.read)['error']
      rescue Mixpanel::URI::FinishError
      end
    end

    class Mixpanel::URI::FinishError < Exception; end

    def self.get(uri)
      uri      = URI(uri)
      use_ssl  = uri.scheme == 'https'
      tempfile = Tempfile.new('mixpanel_export')

      begin
        Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl) do |http|
          request  = Net::HTTP::Get.new uri

          http.request(request) do |response|
            open tempfile, 'w' do |io|
              response.read_body do |chunk|
                io.write chunk
              end
            end
          end
        end
      rescue Net::HTTPError => error
        raise HTTPError, JSON.parse(error.io.read)['error']
      end

      string = String.new
      open(tempfile) do |file|
        while chunk = file.read(512)
          string << chunk
        end
      end

      string
    end
  end
end
