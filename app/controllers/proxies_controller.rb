# frozen_string_literal: true

# Controller responsible for managing proxies.
class ProxiesController < ApplicationController
  include ProxyConcern

  def new
    @proxy = Proxy.new
    respond_to(&:js)
  end

  def edit
    respond_to(&:js)
  end

  def create
    message = I18n.t("proxy.create.#{Proxy.create(proxy_params) ? 'success' : 'failure'}")
    redirect_to request.referer, notice: message
  end

  def update
    message = I18n.t("proxy.update.#{@proxy.update(proxy_params) ? 'success' : 'failure'}")
    redirect_to request.referer, notice: message
  end

  def destroy
    message = I18n.t("proxy.destroy.#{@proxy.destroy ? 'success' : 'failure'}")
    respond_to do |format|
      format.js { render json: { message: message }.to_json }
    end
  end
end
