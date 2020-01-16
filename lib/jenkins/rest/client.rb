require "jenkins/rest/client/version"
require "json"

require "faraday"

module Jenkins
  module Rest
    class Client
      attr_reader :server
      def initialize(server:, username:, password:)
        @server = Faraday.new(server) do |connection|
          connection.basic_auth(username, password)
          connection.adapter(Faraday.default_adapter)
        end
      end
      def job(job)
        return Job.new(JSON.parse(@server.get("/job/#{job}/api/json").body), @server)
      end
    end

    class Artifact < OpenStruct
      def initialize(json, build, server)
        super(json)
        @build = build
        @server = server
      end
      def get
        artifact_url = "#{@build.url}/artifact/#{relativePath}"
        return @server.get(artifact_url).body
      end
    end

    class Build < OpenStruct
      def initialize(json, server)
        super(json)
        @server = server
      end
      def artifacts
        return JSON.parse(@server.get("#{url}/api/json").body)["artifacts"].map{|i|Artifact.new(i, self, @server)}
      end
    end

    class Job < OpenStruct
      def initialize(json, server)
        super(json)
        @server = server
      end
      def last_successful_build
        content = JSON.parse(@server.get("#{url}/api/json").body)
        return Build.new(content["lastSuccessfulBuild"], @server)
      end
      def builds
        content = JSON.parse(@server.get("#{url}/api/json").body)
        return content["builds"].map{|b|Build.new(b, @server)}
      end
    end
  end
end
