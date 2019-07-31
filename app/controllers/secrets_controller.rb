# frozen_string_literal: true

require 'English'

class SecretsController < RestController
  include FindResource
  include AuthorizeResource
  
  before_filter :current_user
  
  def create
    begin
      # Action code
      authorize :update
      value = request.raw_post
      raise ArgumentError, "action_1" if value.eql?("action_1")
      raise ArgumentError, "'value' may not be empty" if value.blank?

      Secret.create resource_id: resource.id, value: value
      raise ArgumentError, "action_2" if value.eql?("action_2")
      resource.enforce_secrets_version_limit
      raise ArgumentError, "action_3" if value.eql?("action_3")
      # Audit success code
      props = {}
      db = Sequel.connect 'postgres://:5433/audit'
      raise ArgumentError, "s_audit_1" if value.eql?("s_audit_1")
      db.transaction do
        raise ArgumentError, "s_audit_2" if value.eql?("s_audit_2")
        ConjurAudit::Message.set_dataset db[:messages]
        raise ArgumentError, "s_audit_3" if value.eql?("s_audit_3")
        sdata = props[:sdata]
        ConjurAudit::Message.create({facility: 4, severity: 5, timestamp: Time.now, message: value, sdata: sdata && Sequel.pg_jsonb(sdata)}.merge(props.except(:sdata)))
        raise ArgumentError, "s_audit_4" if value.eql?("s_audit_4")
      end
      raise ArgumentError, "action_4" if value.eql?("action_4")
      head :created
      raise ArgumentError, "action_5" if value.eql?("action_5")
    end
    raise ArgumentError, "function_end" if value.eql?("function_end")
  end

  def show
    authorize :execute
    version = params[:version]

    unless (secret = resource.secret version: version)
      raise Exceptions::RecordNotFound.new \
        resource.id, message: "Requested version does not exist"
    end
    value = secret.value

    mime_type = \
      resource.annotation('conjur/mime_type') || 'application/octet-stream'

    send_data value, type: mime_type
  ensure
    audit_fetch resource!, version: version
  end

  def batch
    variables = Resource.where(resource_id: variable_ids).eager(:secrets).all

    unless variable_ids.count == variables.count
      raise Exceptions::RecordNotFound,
            variable_ids.find { |r| !variables.map(&:id).include?(r) }
    end
    
    result = {}

    authorize_many variables, :execute
    
    variables.each do |variable|
      unless (secret = variable.last_secret)
        raise Exceptions::RecordNotFound, variable.resource_id
      end
      
      result[variable.resource_id] = secret.value
      audit_fetch variable
    end

    render json: result
  end

  def audit_fetch resource, version: nil
    # don't audit the fetch if the resource doesn't exist
    return unless resource

    Audit::Event::Fetch.new(
      error_info.merge(
        resource: resource,
        version: version,
        user: current_user
      )
    ).log_to Audit.logger
  end

  def error_info
    return { success: true } unless $ERROR_INFO

    # If resource is not visible, the error info will say it cannot be found.
    # That is still what we want to report to the client, but in the log we
    # want more accurate 'Forbidden'.
    {
      success: false,
      error_message: (resource_visible? ? $ERROR_INFO.message : 'Forbidden')
    }
  end

  # NOTE: We're following REST/http semantics here by representing this as 
  #       an "expirations" that you POST to you.  This may seem strange given
  #       that what we're doing is simply updating an attribute on a secret.
  #       But keep in mind this purely an implementation detail -- we could 
  #       have implemented expirations in many ways.  We want to expose the
  #       concept of an "expiration" to the user.  And per standard rest, 
  #       we do that with a resource, "expirations."  Expiring a variable
  #       is then a matter of POSTing to create a new "expiration" resource.
  #       
  #       It is irrelevant that the server happens to implement this request
  #       by assigning nil to `expires_at`.
  #
  #       Unfortuneatly, to be consistent with our other routes, we're abusing
  #       query strings to represent what is in fact a new resource.  Ideally,
  #       we'd use a slash instead, but decided that consistency trumps 
  #       correctness in this case.
  #
  def expire
    authorize :update
    Secret.update_expiration(resource.id, nil)
    head :created
  end

  private

  def variable_ids
    @variable_ids ||= (params[:variable_ids] || '').split(',').compact
      .tap { |ids| raise ArgumentError, 'variable_ids' if ids.empty? }
  end
end
