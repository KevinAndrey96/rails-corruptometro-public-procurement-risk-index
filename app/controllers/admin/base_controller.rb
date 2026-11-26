module Admin
  # Every admin action requires a signed-in user through the Authentication concern.
  class BaseController < ApplicationController
  end
end
