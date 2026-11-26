class Current < ActiveSupport::CurrentAttributes
  attribute :session, :bulk_import
  delegate :user, to: :session, allow_nil: true
end
