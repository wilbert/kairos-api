require 'multi_json'
require 'hashie'
require 'json'

module Kairos
  class Client
    # Define the same set of accessors as the Kairos module
    attr_accessor *Configuration::VALID_CONFIG_KEYS

    def initialize(options={})
      # Merge the config values from the module and those passed
      # to the client.
      merged_options = Kairos.options.merge(options)

      # Copy the merged values to this client and ignore those
      # not part of our configuration
      Configuration::VALID_CONFIG_KEYS.each do |key|
        send("#{key}=", merged_options[key])
      end
    end

    # Enroll an Image
    #
    # Example Usage:
    #  - require 'kairos'
    #  - client = Kairos::Client.new(:app_id => '1234', :app_key => 'abcde1234')
    #  - client.enroll(:url => 'https://some.url.com/to_some.jpg', :subject_id => 'gemtest', :gallery_name => 'testgallery')
    def enroll(options={})
      post_to_api(Kairos::Configuration::ENROLL, options)
    end

    # Recognize an Image
    #
    # Example Usage:
    #  - require 'kairos'
    #  - client = Kairos::Client.new(:app_id => '1234', :app_key => 'abcde1234')
    #  - client.recognize(:url => 'https://some.url.com/to_some_other_image.jpg', :gallery_name => 'testgallery', :threshold => '.2', :max_num_results => '5')
    def recognize(options={})
      post_to_api(Kairos::Configuration::RECOGNIZE, options)
    end

    # Remove Subject from Gallery
    #
    # Example Usage:
    #  - require 'kairos'
    #  - client = Kairos::Client.new(:app_id => '1234', :app_key => 'abcde1234')
    #  - client.gallery_remove_subject(:gallery_name => 'testgallery', :subject_id => 'gemtest')
    def gallery_remove_subject(options={})
      post_to_api(Kairos::Configuration::GALLERY_REMOVE_SUBJECT, options)
    end

    # Detect faces in Image
    #
    # Example Usage:
    #  - require 'kairos'
    #  - client = Kairos::Client.new(:app_id => '1234', :app_key => 'abcde1234')
    #  - client.detect(:url => 'https://some.url.com/to_some_other_image.jpg', :selector => 'FULL')
    def detect(options={})
      post_to_api(Kairos::Configuration::DETECT, options)
    end

    # List all Galleries
    #
    # Example Usage:
    #  - require 'kairos'
    #  - client = Kairos::Client.new(:app_id => '1234', :app_key => 'abcde1234')
    #  - client.gallery_list_all
    def gallery_list_all
      # ToDo: Research why Typhoeus works better than Faraday for this endpoint
      request = Typhoeus::Request.new(
        "#{Kairos::Configuration::GALLERY_LIST_ALL}",
        method: :post,
        headers: { "Content-Type" => "application/json",
                   "app_id"       => "#{@app_id}",
                   "app_key"      => "#{@app_key}" }
      )
      response = request.run
      JSON.parse(response.body) rescue "INVALID_JSON: #{response.body}"
    end

    # View subjects in Gallery
    #
    # Example Usage:
    #  - require 'kairos'
    #  - client = Kairos::Client.new(:app_id => '1234', :app_key => 'abcde1234')
    #  - client.gallery_view(:gallery_name => 'testgallery')
    def gallery_view(options={})
      post_to_api(Kairos::Configuration::GALLERY_VIEW, options)
    end

    private

    def post_to_api(endpoint, options={})
      connection = api_set_connection(endpoint)
      response   = options.empty? ? api_post(connection) : api_post(connection, options)
      JSON.parse(response.body) rescue "INVALID_JSON: #{response.body}"
    end

    def api_set_connection(endpoint)
      Faraday.new(:url => endpoint) do |builder|
        builder.use Faraday::Adapter::NetHttp
      end
    end

    def api_post(connection, options={})
      connection.post do |request|
        request.headers['Content-Type'] = 'application/json'
        request.headers['app_id']       = @app_id
        request.headers['app_key']      = @app_key
        request.body                    = options.empty? ? nil : options.to_json
      end
    end
  end
end
