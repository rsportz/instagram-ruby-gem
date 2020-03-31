module Instagram
  class Client
    # Defines methods related to users
    module Users
      # Returns extended information of a given user
      # @format :json
      #
      # @see https://developers.facebook.com/docs/instagram-basic-display-api/reference/user
      def user(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        id = args.first || 'me'
        response = graph_get("#{id}", options)
        response
      end
    end


    # Returns a list of recent media items for a given user
    # @format :json
    #
    # @see https://developers.facebook.com/docs/instagram-basic-display-api/reference/user/media
    def user_recent_media(*args)
      options = args.last.is_a?(Hash) ? args.pop.select{|k,v| v.present?} : {}
      options[:fields] = media_query_fields
      id = args.first || "me"
      response = graph_get("#{id}/media", options)
      response
    end

    def media_query_fields
      'id,username,caption,media_type,media_url,permalink,thumbnail_url,timestamp'
    end
  end
end
