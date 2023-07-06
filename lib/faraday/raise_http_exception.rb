require 'faraday'

# @private
module FaradayMiddleware
  # @private
  class RaiseHttpException < Faraday::Middleware
    TOKEN_EXPIRED_ERROR_CODES = {
      '190' => 'Access token has expired',
      '460' => 'Password Changed',
      '463' => 'Login status or access token has expired, been revoked, or is otherwise invalid',
      '467' => 'Access token has expired, been revoked, or is otherwise invalid',
      '492' => 'Invalid Session'
    }

    def call(env)
      @app.call(env).on_complete do |response|
        case response[:status].to_i
        when 400
          if access_token_expired?(response)
            raise Instagram::AccessTokenExpired, error_message_400(response, token_expired_message(response))
          else
            raise Instagram::BadRequest, error_message_400(response, 'Invalid OAuth access token')
          end
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

    def token_expired_message(response)
      TOKEN_EXPIRED_ERROR_CODES[error_code(response)]
    end

    def access_token_expired?(response)
      body = error_body(response[:body])

      if body.present?
        code = error_code(response)
        if code.present?
          return TOKEN_EXPIRED_ERROR_CODES[code.to_s].present?
        end
      end

      false
    end

    def error_message_400(response, body=nil)
      "#{response[:method].to_s.upcase} #{response[:url].to_s}: #{[response[:status].to_s + ':', error_body_message(response), body].compact.join(' ')}"
    end

    def error_message_500(response, body=nil)
      "#{response[:method].to_s.upcase} #{response[:url].to_s}: #{[response[:status].to_s + ':', error_body_message(response), body].compact.join(' ')}"
    end

    def error_body(body)
      # body gets passed as a string, not sure if it is passed as something else from other spots?
      if not body.nil? and not body.empty? and body.kind_of?(String)
        # removed multi_json thanks to wesnolte's commit
        body = ::JSON.parse(body) rescue body
      end

      body
    end

    def error_code(response)
      body = error_body(response[:body])
      body.dig('error', 'code')
    rescue
      response.dig(:status)
    end

    def error_body_message(response)
      body = error_body(response['body'])

      if body.nil?
        nil
      elsif body.is_a?(Hash) && (msg = body.dig('error', 'message')).present?
        ": #{msg}"
      else
        ": #{body.to_s}"
      end
    end
  end
end
