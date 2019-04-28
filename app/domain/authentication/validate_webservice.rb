# frozen_string_literal: true

require 'authentication/webservices'

module Authentication
  ValidateWebService = CommandClass.new(
    dependencies: {
      role_class: ::Authentication::MemoizedRole,
      webservice_resource_class: ::Resource,
      logger: Rails.logger
    },
    inputs: %i(webservice enabled_authenticators)
  ) do

    def call
      # No checks required for default conjur authn
      return if default_conjur_authn?

      validate_webservice_is_whitelisted
      validate_webservice_exists
    end

    private

    def default_conjur_authn?
      @webservice.authenticator_name ==
        ::Authentication::Common.default_authenticator_name
    end

    def validate_webservice_exists
      raise ServiceNotDefined, @webservice.name unless webservice_resource
    end

    def validate_webservice_is_whitelisted
      is_whitelisted = whitelisted_webservices.include?(@webservice)
      raise NotWhitelisted, @webservice.name unless is_whitelisted
    end

    def webservice_resource
      @webservice_resource_class[webservice_resource_id]
    end

    def webservice_resource_id
      @webservice.resource_id
    end

    def whitelisted_webservices
      ::Authentication::Webservices.from_string(
        @account,
        @enabled_authenticators || Authentication::Common.default_authenticator_name
      )
    end
  end
end
