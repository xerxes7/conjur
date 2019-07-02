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

  let(:authenticator_mock) do
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:authenticator_name).and_return("authn-x")
    end
  end

  let (:full_access_resource_class) { resource_class('some random resource') }
  let (:no_access_resource_class) { resource_class(nil) }

  let (:nil_user_role_class) { role_class(nil) }
  let (:non_existing_account_role_class) { role_class(nil) }
  let (:full_access_role_class) { role_class(user_role(is_authorized: true)) }
  let (:no_access_role_class) { role_class(user_role(is_authorized: false)) }

  let(:mock_validate_whitelisted_webservice) { double("ValidateWhitelistedWebservice") }
  let(:mock_validate_webservice_access) { double("ValidateWebserviceAccess") }

  before(:each) do
    allow(Authentication::Security::ValidateWhitelistedWebservice)
      .to receive(:new)
            .and_return(mock_validate_whitelisted_webservice)
    allow(mock_validate_whitelisted_webservice).to receive(:call)
                                                .and_return(true)

    allow(Authentication::Security::ValidateWebserviceAccess)
      .to receive(:new)
            .and_return(mock_validate_webservice_access)
    allow(mock_validate_webservice_access).to receive(:call)
                                           .and_return(true)
  end

  context "A whitelisted, accessible webservice" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        validate_whitelisted_webservice: mock_validate_whitelisted_webservice,
        validate_webservice_access: mock_validate_webservice_access
      ).(
        webservice: authenticator_mock,
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
        validate_whitelisted_webservice: mock_validate_whitelisted_webservice,
        validate_webservice_access: mock_validate_webservice_access
      ).(
        webservice: authenticator_mock,
          account: test_account,
          user_id: test_user_id,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises the error that is raised by validate_webservice_access" do
      allow(mock_validate_webservice_access)
        .to receive(:call)
              .and_raise("webservice-access-validation-error")
      
      expect { subject }.to raise_error("webservice-access-validation-error")
    end
  end

  context "An un-whitelisted, accessible webservice" do
    subject do
      Authentication::Security::ValidateSecurity.new(
        validate_whitelisted_webservice: mock_validate_whitelisted_webservice,
        validate_webservice_access: mock_validate_webservice_access
      ).(
        webservice: authenticator_mock,
          account: test_account,
          user_id: test_user_id,
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises the error that is raised by validate_whitelisted_webservice" do

      allow(mock_validate_whitelisted_webservice)
        .to receive(:call)
              .and_raise("whitelisted-webservice-validation-error")

      expect { subject }.to raise_error("whitelisted-webservice-validation-error")
    end
  end
end
