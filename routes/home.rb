# frozen_string_literal: true

get '/' do
  @links = {
    '/sample-form' => 'Test a sample form',
    '/database' => 'Test a database connection',
    '/login' => 'Test login'
  }

  erb :home
end
