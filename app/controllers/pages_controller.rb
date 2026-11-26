class PagesController < ApplicationController
  allow_unauthenticated_access

  def methodology
    @windows = ElectoralCalendar.restricted_windows
  end
end
