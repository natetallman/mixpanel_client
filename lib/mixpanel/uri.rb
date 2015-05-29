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

    def self.get(uri)
      uri        = URI(uri)
      enable_ssl = uri.scheme == 'https'
      string   = ''
      tempfile = Tempfile.new('mixpanel_export')

      Net::HTTP.start(uri.host, uri.port, use_ssl: enable_ssl) do |http|
        request  = Net::HTTP::Get.new uri

        http.request(request) do |response|
          open tempfile, 'w' do |io|
            response.read_body do |chunk|
              io.write chunk
            end
          end
        end
      end

      open(tempfile) do |file|
        while chunk = file.read(512)
          string << chunk
        end
      end

      string
    end
  end
end
