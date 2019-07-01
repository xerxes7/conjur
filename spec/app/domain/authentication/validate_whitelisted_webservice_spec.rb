# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Security::ValidateWhitelistedWebservice do
  let (:test_account) { 'test-account' }
  let (:non_existing_account) { 'non-existing' }
  let (:fake_authenticator_name) { 'authn-x' }

  def mock_webservice(resource_id)
    double('webservice').tap do |webservice|
      allow(webservice).to receive(:name)
                             .and_return("some-string")

      allow(webservice).to receive(:resource_id)
                             .and_return(resource_id)

      allow(webservice).to receive(:status_webservice)
                             .and_return(mock_status_webservice(resource_id))
    end
  end

  # generates a Resource class which returns the provided object
  def resource_class(returned_resource)
    double('Resource').tap do |resource_class|
      allow(resource_class).to receive(:[]).and_return(returned_resource)
    end
  end

  let (:blank_env) { nil }

  let (:two_authenticator_env) { "#{fake_authenticator_name}/service1, #{fake_authenticator_name}/service2" }

  let (:not_including_env) do
    "authn-other/service1"
  end

  let(:default_authenticator_mock) do
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:authenticator_name).and_return("authn")
    end
  end

  def role_class(returned_role)
    double('role_class').tap do |role|
      allow(role).to receive(:roleid_from_username).and_return('some-role-id')
      allow(role).to receive(:[]).and_return(returned_role)

      allow(role).to receive(:[])
                       .with(/#{test_account}:user:admin/)
                       .and_return(user_role(is_authorized: true))

      allow(role).to receive(:[])
                       .with(/#{non_existing_account}:user:admin/)
                       .and_return(nil)
    end
  end

  let (:non_existing_account_role_class) { role_class(nil) }

  def webservices_dict(includes_authenticator:)
    double('webservices_dict').tap do |webservices_dict|
      allow(webservices_dict).to receive(:include?)
                                   .and_return(includes_authenticator)
    end
  end

  def mock_webservices_class
    double('webservices_class').tap do |webservices_class|


      allow(webservices_class).to receive(:from_string)
                                    .with(anything, two_authenticator_env)
                                    .and_return(webservices_dict(includes_authenticator: true))

      allow(webservices_class).to receive(:from_string)
                                    .with(anything, not_including_env)
                                    .and_return(webservices_dict(includes_authenticator: false))

      allow(webservices_class).to receive(:from_string)
                                    .with(anything, blank_env)
                                    .and_return(webservices_dict(includes_authenticator: false))
    end
  end

  context "A whitelisted webservice" do
    subject do
      Authentication::Security::ValidateWhitelistedWebservice.new(
        role_class: full_access_role_class,
        webservices_class: mock_webservices_class
      ).(
        webservice: mock_webservice("#{fake_authenticator_name}/service1"),
          account: test_account,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A un-whitelisted webservice" do
    subject do
      Authentication::Security::ValidateWhitelistedWebservice.new(
        role_class: full_access_role_class,
        webservices_class: mock_webservices_class
      ).(
        webservice: mock_webservice("#{fake_authenticator_name}/service1"),
          account: test_account,
          enabled_authenticators: not_including_env
      )
    end

    it "raises a NotWhitelisted error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::NotWhitelisted)
    end
  end

  context "An ENV lacking CONJUR_AUTHENTICATORS" do
    subject do
      Authentication::Security::ValidateWhitelistedWebservice.new(
        role_class: full_access_role_class,
        webservices_class: mock_webservices_class
      ).(
        webservice: default_authenticator_mock,
          account: test_account,
          enabled_authenticators: blank_env
      )
    end

    it "the default Conjur authenticator is included in whitelisted webservices" do
      expect { subject }.to_not raise_error
    end
  end

  context "A non-existing account" do
    subject do
      Authentication::Security::ValidateWhitelistedWebservice.new(
        role_class: non_existing_account_role_class,
        webservices_class: mock_webservices_class
      ).(
        webservice: mock_webservice("#{fake_authenticator_name}/service1"),
          account: non_existing_account,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises an AccountNotDefined error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::AccountNotDefined)
    end
  end
end
