require 'faraday_middleware'
Dir[File.expand_path('../../faraday/*.rb', __FILE__)].each{|f| require f}

module Instagram
  # @private
  module Connection
    private

    def connection(raw=false, graph_request=false)
      end_point = graph_request ? graph_api_endpoint : token_endpoint

      options = {
        :headers => {'Accept' => "application/#{format}; charset=utf-8", 'User-Agent' => user_agent},
        :proxy => proxy,
        :url => end_point,
      }.merge(connection_options)

      Faraday::Connection.new(options) do |connection|
        connection.use FaradayMiddleware::InstagramOAuth2, client_id, access_token
        connection.use Faraday::Request::UrlEncoded
        connection.use FaradayMiddleware::Mashify unless raw
        unless raw
          case format.to_s.downcase
          when 'json' then connection.use Faraday::Response::ParseJson
          end
        end
        connection.use FaradayMiddleware::RaiseHttpException
        connection.use FaradayMiddleware::LoudLogger if loud_logger
        connection.adapter(adapter)
      end
    end
  end
end
