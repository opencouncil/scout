# router helpers, can also be mixed in elsewhere if need be
module Helpers
  module Routing
    
    def item_path(item)
      if item.interest_type == "external_feed"
        item.data['link']

      # an item with its own landing page
      elsif item.interest_type == "search"
        "/item/#{item.item_type}/#{item.item_id}"

      # an item that does not have its own landing page
      else # "item"
        "/item/#{item.item_type}/#{item.interest_in}##{item.item_id}"
      end
    end

    def item_url(item)
      if item.subscription_type == "external_feed"
        item.data['link']
      else
        "http://#{config[:hostname]}#{item_path item}"
      end
    end

    # only needed in RSS feeds, and external feeds are the only time we override the guid
    def item_guid(item)
      if item.subscription_type == "external_feed"
        item.data['guid']
      else
        item_url item
      end
    end

    # given a subscription, serialize it to a URL
    # assumes it is a search subscription
    def subscription_path(subscription)
      base = "/search/#{subscription.subscription_type}"
      
      base << "/#{URI.encode subscription.data['query']}" if subscription.data['query']

      query_string = subscription.filters.map do |key, value| 
        "#{subscription.subscription_type}[#{key}]=#{URI.encode value}"
      end.join("&")
      base << "?#{query_string}" if query_string.present?

      base
    end

    # given an interest, serialize it to a URL
    # assumes it is a search interest
    def search_interest_path(interest)
      if interest.search_type == "all"
        base = "/search/all"
        base << "/#{URI.encode interest.data['query']}" if interest.data['query']
        base
      else
        subscription_path interest.subscriptions.first
      end
    end


  end
end