# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::Security::ValidateSecurity do
  let (:test_account) { 'test-account' }
  let (:non_existing_account) { 'non-existing' }
  let (:fake_authenticator_name) { 'authn-x' }
  let (:test_user_id) { 'some-user' }

  # create an example webservice
  def webservice(service_id, account: test_account, authenticator_name: fake_authenticator_name)
    ::Authentication::Webservice.new(
      account: account,
      authenticator_name: authenticator_name,
      service_id: service_id
    )
  end

  # generates user_role authorized for all or no services
  def user_role(is_authorized:)
    double('user_role').tap do |role|
      allow(role).to receive(:allowed_to?).and_return(is_authorized)
    end
  end

  # generates user_role authorized for specific service
  def user_role_for_service(authorized_service)
    double('user_role').tap do |role|
      allow(role).to(receive(:allowed_to?)) do |_, resource|
        resource == authorized_service
      end
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

  # generates a Resource class which returns the provided object
  def resource_class(returned_resource)
    double('Resource').tap do |resource_class|
      allow(resource_class).to receive(:[]).and_return(returned_resource)
    end
  end

  let (:blank_env) { nil }

  let (:two_authenticator_env) { "#{fake_authenticator_name}/service1, #{fake_authenticator_name}/service2" }

  let(:default_authenticator_mock) do
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:authenticator_name).and_return("authn")
    end
  end

  let (:full_access_resource_class) { resource_class('some random resource') }
  let (:no_access_resource_class) { resource_class(nil) }

  let (:nil_user_role_class) { role_class(nil) }
  let (:non_existing_account_role_class) { role_class(nil) }
  let (:full_access_role_class) { role_class(user_role(is_authorized: true)) }
  let (:no_access_role_class) { role_class(user_role(is_authorized: false)) }

  let(:validate_whitelisted_webservice) { double("ValidateWhitelistedWebservice") }
  let(:validate_webservice_access) { double("ValidateWebserviceAccess") }

  before(:each) do
    allow(Authentication::Security::ValidateWhitelistedWebservice)
      .to receive(:new)
            .and_return(validate_whitelisted_webservice)

    allow(Authentication::Security::ValidateWebserviceAccess)
      .to receive(:new)
            .and_return(validate_webservice_access)
  end

  def mock_whitelisted_webservice_validator(validation_succeeds:)
    if validation_succeeds
      allow(validate_whitelisted_webservice).to receive(:call)
    else
      allow(validate_whitelisted_webservice).to receive(:call)
                            .and_raise("whitelisted-webservice-validation-error")
    end
  end

  def mock_webservice_access_validator(validation_succeeds:)
    if validation_succeeds
      allow(validate_webservice_access).to receive(:call)
    else
      allow(validate_webservice_access).to receive(:call)
                                                  .and_raise("webservice-access-validation-error")
    end
  end

  context "A whitelisted, accessible webservice" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        validate_whitelisted_webservice: mock_whitelisted_webservice_validator(validation_succeeds: true),
        validate_webservice_access: mock_webservice_access_validator(validation_succeeds: true)
      ).(
        webservice: default_authenticator_mock,
          account: test_account,
          user_id: test_user_id,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A whitelisted, inaccessible webservice and authorized user" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        validate_whitelisted_webservice: mock_whitelisted_webservice_validator(validation_succeeds: true),
        validate_webservice_access: mock_webservice_access_validator(validation_succeeds: false)
      ).(
        webservice: default_authenticator_mock,
          account: test_account,
          user_id: test_user_id,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises a webservice-access validation error" do
      expect { subject }.to raise_error("webservice-access-validation-error")
    end
  end

  context "An un-whitelisted, accessible webservice" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        validate_whitelisted_webservice: mock_whitelisted_webservice_validator(validation_succeeds: false),
        validate_webservice_access: mock_webservice_access_validator(validation_succeeds: true)
      ).(
        webservice: default_authenticator_mock,
          account: test_account,
          user_id: test_user_id,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises a whitelisted-webservice validation error" do
      expect { subject }.to raise_error("whitelisted-webservice-validation-error")
    end
  end

  # context "Two whitelisted, authorized webservices" do
  #   context "and a user authorized for only one on them" do
  #     let (:webservice_resource) { 'CAN ACCESS ME' }
  #     let (:partial_access_role_class) do
  #       role_class(user_role_for_service(webservice_resource))
  #     end
  #     let (:accessible_resource_class) { resource_class(webservice_resource) }
  #     let (:inaccessible_resource_class) { resource_class('CANNOT ACCESS ME') }
  #
  #     context "when accessing the authorized one" do
  #       subject do
  #         Authentication::Security::ValidateSecurity.new(
  #           role_class: partial_access_role_class,
  #           resource_class: accessible_resource_class
  #         ).(
  #           webservice: webservice('service1'),
  #             account: test_account,
  #             user_id: 'some-user',
  #             enabled_authenticators: two_authenticator_env
  #         )
  #       end
  #
  #       it "succeeds" do
  #         expect { subject }.to_not raise_error
  #       end
  #     end
  #
  #     context "when accessing the blocked one" do
  #       subject do
  #         Authentication::Security::ValidateSecurity.new(
  #           role_class: partial_access_role_class,
  #           resource_class: inaccessible_resource_class
  #         ).(
  #           webservice: webservice('service1'),
  #             account: test_account,
  #             user_id: 'some-user',
  #             enabled_authenticators: two_authenticator_env
  #         )
  #       end
  #
  #       it "fails" do
  #         expect { subject }.to raise_error(Errors::Authentication::Security::UserNotAuthorizedInConjur)
  #       end
  #     end
  #   end
  # end

end
