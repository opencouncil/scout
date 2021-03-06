module Subscriptions  
  module Adapters

    class FederalBills

      def self.filters
        {
          "stage" => {
            name: -> v {v.split("_").map(&:capitalize).join " "}
          }
        }
      end

      def self.url_for(subscription, function, options = {})
        api_key = options[:api_key] || config[:subscriptions][:sunlight_api_key]
        
        if config[:subscriptions][:congress_endpoint].present?
          endpoint = config[:subscriptions][:congress_endpoint].dup
        else
          endpoint = "http://congress.api.sunlightfoundation.com"
        end
        
        fields = %w{ bill_id bill_type number congress
          short_title official_title summary
          introduced_on last_version last_version_on
        }

        url = endpoint

        query = subscription.query['query']
        if query.present?
          url << "/bills/search?"
          url << "&query=#{CGI.escape query}"

          url << "&highlight=true"
          url << "&highlight.size=500"
          url << "&highlight.tags=,"
        else
          url << "/bills?"
        end

        if subscription.query['citations'].any?
          citations = subscription.query['citations'].map {|c| c['citation_id']}
          url << "&citing=#{citations.join "|"}"
          url << "&citing.details=true"
        end

        url << "&order=last_version_on"
        url << "&fields=#{fields.join ','}"
        url << "&apikey=#{api_key}"


        # filters

        if subscription.data["stage"].present?
          stage = subscription.data["stage"]
          if stage == "enacted"
            url << "&history.enacted=true"
          elsif stage == "passed_house"
            url << "&history.house_passage_result=pass"
          elsif stage == "passed_senate"
            url << "&history.senate_passage_result=pass"
          elsif stage == "vetoed"
            url << "&history.vetoed=true"
          elsif stage == "awaiting_signature"
            url << "&history.awaiting_signature=true"
          end
        end

        # if it's background checking, filter to just the last month for speed
        if function == :check
          url << "&last_version_on__gte=#{1.month.ago.strftime "%Y-%m-%d"}"
        end

        if options[:page]
          url << "&page=#{options[:page]}"
        end

        per_page = (function == :search) ? (options[:per_page] || 20) : 40
        url << "&per_page=#{per_page}"
        
        url
      end

      def self.url_for_detail(item_id, options = {})
        api_key = options[:api_key] || config[:subscriptions][:sunlight_api_key]

        if config[:subscriptions][:congress_endpoint].present?
          endpoint = config[:subscriptions][:congress_endpoint].dup
        else
          endpoint = "http://congress.api.sunlightfoundation.com"
        end
        
        fields = %w{ 
          bill_id bill_type number congress
          sponsor urls
          short_title official_title summary
          introduced_on last_action_at last_version last_version_on
        }

        url = "#{endpoint}/bills?apikey=#{api_key}"
        url << "&bill_id=#{item_id}"
        url << "&fields=#{fields.join ','}"

        url
      end

      def self.search_name(subscription)
        "Bills in Congress"
      end

      def self.short_name(number, interest)
        "#{number > 1 ? "bills" : "bill"}"
      end

      def self.interest_name(interest)
        code = {
          "hr" => "H.R.",
          "hres" => "H.Res.",
          "hjres" => "H.J.Res.",
          "hconres" => "H.Con.Res.",
          "s" => "S.",
          "sres" => "S.Res.",
          "sjres" => "S.J.Res.",
          "sconres" => "S.Con.Res."
        }[interest.data['bill_type']]
        "#{code} #{interest.data['number']}"
      end

      def self.interest_subtitle(interest)
        interest.data['short_title'] || interest.data['official_title']
      end
      
      # takes parsed response and returns an array where each item is 
      # a hash containing the id, title, and post date of each item found
      def self.items_for(response, function, options = {})
        raise AdapterParseException.new("Response didn't include results field: #{response.inspect}") unless response['results']
        
        response['results'].map do |bv|
          item_for bv
        end
      end

      # parse response when asking for a single bill - Congress API returns an array of one
      def self.item_detail_for(response)
        return nil unless response
        item_for response['results'][0]
      end
      
      def self.item_for(bill)
        return nil unless bill

        SeenItem.new(
          item_id: bill["bill_id"],
          date: bill['last_version_on'],
          data: bill
        )
      end
      
    end
  
  end
end