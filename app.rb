# frozen_string_literal: true

configure do
  set :session_timeout, 8 * 3600 # seconds

  config_file 'config.yaml'
  # aws_config if in_lambda?

  # Faculty-specific
  # Check that the web library version is a numeric (tagged) version if we're in production
  # only_versioned_web_library_in_production!

  ## Connect to database
  # settings.db ||= {}
  # settings.db[:noauto] = true unless in_lambda?
  DB = Sequel.connect('sqlite://mcm.db')
  # DB = FacultyAWS::DBConnector.new(**settings.db).connection
  # RBAC = FacultyRBAC::Controller.new(DB)
  LOGGER = Logger.new $stdout
  $stdout.sync = true if development?

  # Constants for app
  set :DEFAULT_MECHANISM, 'MCM'

  # Param setup
  enable :raise_sinatra_param_exceptions
  # Erubi setup - escape html when using <%= %>
  set :erb, escape_html: true

  # if in_lambda?
  #  register Sinatra::CognitoAuth
  # elsif production?
  #  raise 'No production session/auth available outside AWS'
  # else
  #  register Sinatra::BasicPasswordlessAuth
  #  use Rack::Session::Cookie, secret: 'local_secret'
  # end
  use Rack::Session::Cookie, secret: 'local_secret'

  use Rack::Protection::StrictTransport
  use Rack::Protection

  # Faculty-specific
  # register FacultyRBAC::Sinatra
  register Sinatra::Banner

  set :show_exceptions, :after_handler if development?
  disable :dump_errors unless development?
end

helpers FacultyHelpers

before do
  cache_control :no_cache

  # Force all routes to have explicitly have mechanism
  @all_mechanisms = DB[:Mechanisms].order(:DropdownOrder).select(:Mechanism, :CurrentVersion)
  @mechanism = request.path_info.split('/')[1]
  mech = @mechanism # Need normal variable to be able to be used in Sequel
  @mechanism_version = DB[:Mechanisms].where(Mechanism: mech).get(:CurrentVersion)
  unless @all_mechanisms.map(:Mechanism).include? @mechanism
    new_route = "/#{settings.DEFAULT_MECHANISM}" + request.path_info
    redirect new_route
  end

  # unless request.path_info.start_with? '/auth/'
  #   # Faculty-specific
  #   # require_authentication

  #   # @logged_in_user = RBAC.user(session[:username])
  #   # LOGGER.info "Username: #{@logged_in_user.username}"
  # end
end

# Faculty-specific
after do
  DB.disconnect
end

before '/api/*' do
  content_type :json
end

error do
  error = env['sinatra.error']
  LOGGER.error "#{error.class} - #{error.message}"
  LOGGER.error error.backtrace.join("\n\t")

  # Faculty-specific
  # FacultyAWS::NotifyDevs.send_error_warning if settings.in_lambda?

  erb :'error/5xx', locals: { error: http_status(500) }
end

# Load helpers
helpers do
  Dir['./helpers/*.rb'].sort.each do |file|
    require file
  end
end

error_handler Sinatra::HTTPStatus::AnyStatus, :'error/error'
error_handler Sinatra::HTTPStatus::ServerError, :'error/5xx'
error_handler Sinatra::HTTPStatus::Forbidden, :'error/403'
error_handler Sinatra::HTTPStatus::NotFound, :'error/404'
error(Sinatra::NotFound) { erb :'error/404', locals: { error: http_status(404) } }

# Load routes
Dir['./routes/*.rb'].sort.each do |file|
  require file
end
