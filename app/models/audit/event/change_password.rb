# frozen_string_literal: true

module Audit
  class Event
    class ChangePassword < Event
      field :user
      facility Syslog::LOG_AUTH
      message_id 'change_password'
      can_fail

      def structured_data
        super.deep_merge \
          SDID::AUTH => { user: user.id },
          SDID::SUBJECT => { role: user.id },
          SDID::ACTION => { operation: 'change_password' }
      end

      def message
        format "%s changed their password (%s)",
          user.id, success_text
      end
    end
  end
end
