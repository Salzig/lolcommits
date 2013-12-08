require 'yammer'
require 'rest_client'

# https://developer.yammer.com/oauth2-quickstart/
YAMMER_CLIENT_ID        = 'bgORyeKtnjZJSMwp8oln9g'
YAMMER_CLIENT_SECRET    = 'oer2WdGzh74a5QBbW3INUxblHK3yg9KvCZmiBa2r0'
YAMMER_ACCESS_TOKEN_URL = "https://www.yammer.com/oauth2/access_token.json"

module Lolcommits

  class LolYammer < Plugin

    def self.name
      'yammer'
    end

    def is_configured?
      !configuration['access_token'].nil?
    end

    def get_access_token
      print "Open the URL below and copy the `code` param from query after redirected, enter it as `access_token`:\n"
      print "https://www.yammer.com/dialog/oauth?client_id=#{YAMMER_CLIENT_ID}&response_type=code\n"
      print "Enter code param from the redirected URL, then press enter: "
      code = STDIN.gets.to_s.strip

      url = "#{YAMMER_ACCESS_TOKEN_URL}"
      debug "access_token url: #{url}"
      params = {
        "client_id" => YAMMER_CLIENT_ID,
        "client_secret" => YAMMER_CLIENT_SECRET,
        "code" => code
      }
      debug "params : #{params.inspect}"
      result = JSON.parse(RestClient.post(url, params))
      debug "response : #{result.inspect}"
      # no need for 'return', last line is always the return value
      {'access_token' => result["access_token"]["token"]}
    end

    def configure_options!
      options = super
      if options['enabled'] == true
        if auth_config = get_access_token
          options.merge!(auth_config)
        else
          return
        end
      end
      options
    end

    def yammer_client
      @yammer_client ||= Yammer.configure do |c|
        c.client_id = YAMMER_CLIENT_ID
        c.client_secret = YAMMER_CLIENT_SECRET
      end
    end

    def run
      return unless valid_configuration?

      commit_msg = self.runner.message
      post = "#{commit_msg} #lolcommits"
      puts "Yammer post: #{post}" unless self.runner.capture_stealth

      retries = 2
      begin
        lolimage = File.new(self.runner.main_image)
        if yammer_client.create_message(post, :attachment1 => lolimage)
          puts "\t--> Status posted!" unless self.runner.capture_stealth
        end
      rescue => e
        retries -= 1
        retry if retries > 0
        puts "Status not posted - #{e.message}"
        puts "Try running config again:"
        puts "\tlolcommits --config --plugin yammer"
      end
    end
  end
end
