class ApplicationController < ActionController::Base
  include ItemSoldHelper
  before_action :authenticate_user!
end
