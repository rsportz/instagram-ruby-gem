module Instagram
  class Client
    # Defines methods related to users
    module Users
      # Returns extended information of a given user
      #
      # @overload user(id=nil, options={})
      #   @param user [Integer] An Instagram user ID
      #   @return [Hashie::Mash] The requested user.
      #   @example Return extended information for @shayne
      #     Instagram.user(20)
      # @format :json
      # @authenticated false unless requesting it from a protected user
      #
      #   If getting this data of a protected user, you must authenticate (and be allowed to see that user).
      # @rate_limited true
      # @see https://developers.facebook.com/docs/instagram-basic-display-api/reference/user
      def user(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        id = args.first || 'me'
        response = get("#{id}", options, unformatted: true, no_response_wrapper: true, graph_request: true)
        response
      end
    end


    # Returns a list of recent media items for a given user
    #
    # @format :json
    # @authenticated false unless requesting it from a protected user
    #
    # If getting this data of a protected user, you must authenticate (and be allowed to see that user).
    # @ true
    # @see https://developers.facebook.com/docs/instagram-basic-display-api/reference/user/media
    def user_recent_media(*args)
      options = args.last.is_a?(Hash) ? args.pop.select{|k,v| v.present?} : {}
      options[:fields] = [:id, :username, :caption, :media_type, :media_url, :permalink, :thumbnail_url, :timestamp].join(',')
      id = args.first || "me"
      response = get("#{id}/media", options, unformatted: true, no_response_wrapper: true, graph_request: true)
      response
    end
  end
end
