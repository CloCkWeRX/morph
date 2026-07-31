# typed: strict
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  extend T::Sig

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_action :store_location

  # When trying to look at a page on active admin you're not allowed to
  sig { params(exception: StandardError).void }
  def access_denied(exception)
    redirect_to current_user, alert: exception.message
  end

  # Handle omniauth failure. See https://github.com/plataformatec/devise/wiki/OmniAuth%3A-Overview#using-omniauth-without-other-authentications
  sig { params(_scope: T.untyped).returns(String) }
  def new_session_path(_scope)
    new_user_session_path
  end

  private

  sig { void }
  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath unless request.fullpath =~ %r{/users}
  end

  sig { params(_resource: T.untyped).returns(T.nilable(String)) }
  def after_sign_out_path_for(_resource)
    if request.referer && _url_host_allowed?(request.referer)
      request.referer
    else
      root_path
    end
  end

  sig { params(url: T.nilable(String)).returns(T::Boolean) }
  def _url_host_allowed?(url)
    return false if url.nil? || url.blank?

    uri = URI.parse(url)
    host = uri.host

    if host.nil?
      # Only allow relative paths that start with a single slash, not double slashes
      return url.start_with?("/") && !url.start_with?("//") && !url.start_with?("/\\")
    end

    # Otherwise, check if the host matches the current application host
    return true if host == request.host

    # Or check if the host is in our allowed hosts extend list from environment variable
    allowed_hosts = ENV.fetch("ALLOWED_REDIRECT_HOSTS", "").split(",").map(&:strip).reject(&:blank?)
    allowed_hosts.include?(host)
  rescue URI::InvalidURIError, ArgumentError
    false
  end

  # Overriding the default ability class name used because we've split them out. See
  # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/split_ability.md
  # Putting this here we are making it available to the render_sync refetch controller
  # which inherits from this class. I know. It's really ugly. I'm sorry.
  sig { returns(Ability) }
  def current_ability
    @current_ability ||= T.let(ScraperAbility.new(current_user), T.nilable(ScraperAbility))
  end
end
