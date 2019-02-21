require "ruby_apollo/version"
require 'net/http'
require 'json'
require 'yaml'
require 'eventmachine'

module RubyApollo
  class Error < StandardError; end

  class ApolloClient
    # HOST = 'https://apollo-portal.feedmob.com'
    HOST = 'http://106.12.25.204:8080'

    attr_reader :project_name, :cluster, :namespace, :notification_map

    def initialize(project_name, cluster, namespace)
      @project_name = project_name
      @cluster = cluster
      @namespace = namespace
      @notification_map = { application: init_notification_id }
    end

    def start

      Thread.new { 
        EventMachine.run {
           EventMachine.add_periodic_timer(5) {
             long_poll
           } 
        }
      }
    end
    
    def apollo_info
      "#{project_name},#{cluster},#{namespace},#{notification_map[:application]}"
    end

    def init_notification_id
      notification_info = File.read('config/apollo_info.txt')
      record_project_name, record_cluster, record_namespace, record_id = notification_info.split(',')

      if record_project_name == project_name &&
         record_cluster == cluster &&
         record_namespace == namespace &&
         record_id != nil
        return record_id.to_i
      end
      return -1
    end

    def get_cached_data(url)
      uri = URI.parse(url)
      parse_data(Net::HTTP.get(uri))
    end

    def get_uncached_data(url)
      uri = URI.parse(url)
      data = parse_data(Net::HTTP.get(uri))
      p "[Apollo] Get uncached data: #{data}"
      p "[Apollo] Get data url: #{url}"
      write_yml(data)
    end

    def parse_data(data)
      configurations = JSON.parse(data)['configurations']
      return configurations['content']
    end

    def write_yml(data)
      File.write('config/test.yml', data)
    end

    def long_poll
      p '[Apollo] Start get notifications.....'
      url = "#{HOST}/notifications/v2"

      notifications = []
      notifications << { 
        namespaceName: namespace,
        notificationId: notification_map[:application]
      }

      params = {
        appId: project_name,
        cluster: cluster,
        notifications: notifications.to_json
      }

      uri = URI.parse(url)
      uri.query = URI.encode_www_form(params)
      p uri
      response = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 61) do |http|
        # apollo serve will hold 60s request, timeout must > 60
        response = http.request_get(uri.request_uri)
      end
      body = JSON.parse(response.body) if response.body

      if response.code == '200' && body.first['notificationId'] != notification_map[:application]
        p "[Apollo] Api notificatitons v2 config changed: #{body}"
        get_uncached_data(splice_url('configs'))
        notification_map[:application] = body.first['notificationId']
        File.write('config/apollo_info.txt', apollo_info)
      elsif response.code == '304'
        p '[Apollo] There is no HTTPNotModified'
      elsif response.code == '400'
        p '[Apollo] Bad Request with missing params'
      elsif resonse.code == '404'
        p '[Apollo] Not Found with error params'
      end
      rescue Net::ReadTimeout
    end

    def splice_url(pathname)
      "#{HOST}/#{pathname}/#{project_name}/#{cluster}/#{namespace}"
    end
  end
end
