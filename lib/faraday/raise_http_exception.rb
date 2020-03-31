require 'faraday'

# @private
module FaradayMiddleware
  # @private
  class RaiseHttpException < Faraday::Middleware
    def call(env)
      @app.call(env).on_complete do |response|
        case response[:status].to_i
        when 400
          raise Instagram::BadRequest, error_message_400(response, 'Invalid OAuth access token')
        when 404
          raise Instagram::NotFound, error_message_400(response)
        when 429
          raise Instagram::TooManyRequests, error_message_400(response)
        when 500
          raise Instagram::InternalServerError, error_message_500(response, "Something is technically wrong.")
        when 502
          raise Instagram::BadGateway, error_message_500(response, "The server returned an invalid or incomplete response.")
        when 503
          raise Instagram::ServiceUnavailable, error_message_500(response, "Instagram is rate limiting your requests.")
        when 504
          raise Instagram::GatewayTimeout, error_message_500(response, "504 Gateway Time-out")
        end
      end
    end

    def initialize(app)
      super app
      @parser = nil
    end

    private

    def error_message_400(response, body=nil)
      "#{response[:method].to_s.upcase} #{response[:url].to_s}: #{response[:status]} #{error_body(response[:body]) || body}"
    end

    def error_body(body)
      # body gets passed as a string, not sure if it is passed as something else from other spots?
      if not body.nil? and not body.empty? and body.kind_of?(String)
        # removed multi_json thanks to wesnolte's commit
        body = ::JSON.parse(body)
      end

      if body.nil?
        nil
      elsif body['error'] and body['error']['message'] and not body['error']['message'].empty?
        ": #{body['error']['message']}"
      elsif body['error'] and not body['message'].empty?
        ": #{body.to_s}"
      end
    end

    def error_message_500(response, body=nil)
      "#{response[:method].to_s.upcase} #{response[:url].to_s}: #{[response[:status].to_s + ':', error_body(response[:body]) ,body].compact.join(' ')}"
    end
  end
end
