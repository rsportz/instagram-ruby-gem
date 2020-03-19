module Instagram
  # Defines HTTP request methods
  module OAuth
    # Return URL for OAuth authorization
    def authorize_url(options={})
      options[:response_type] ||= "code"
      options[:scope] ||= scope if !scope.nil? && !scope.empty?
      options[:redirect_uri] ||= self.redirect_uri
      params = authorization_params.merge(options)
      connection.build_url("/oauth/authorize/", params).to_s
    end

    # Return an access token from authorization
    def get_access_token(code, options={})
      short_lived_auth = get_short_lived_access_token(code, options)
      res = get_long_lived_access_token(short_lived_auth.access_token)
      res[:user_id] = short_lived_auth[:user_id]

      temp_instagram = Instagram.client(:access_token => res.access_token)
      res[:user] = temp_instagram.user(fields: 'id,username')
      res
    end

    def get_short_lived_access_token(code, options={})
      options[:grant_type] ||= "authorization_code"
      options[:redirect_uri] ||= self.redirect_uri
      params = access_token_params.merge(options)

      post("/oauth/access_token/", params.merge(:code => code), signature=false, raw=false, unformatted=true, no_response_wrapper=true)
    end

    # Returns an access token that will expire for about 60 days
    def get_long_lived_access_token(short_live_access_token, options={})
      options[:grant_type] = 'ig_exchange_token'
      options[:client_secret] = self.client_secret
      options[:access_token] = short_live_access_token
      get("/access_token/", options, signature=false, raw=false, unformatted=true, no_response_wrapper=true, graph_request: true)
    end

    private

    def authorization_params
      {
        :client_id => client_id
      }
    end

    def access_token_params
      {
        :client_id => client_id,
        :client_secret => client_secret
      }
    end
  end
end
