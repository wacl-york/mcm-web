# frozen_string_literal: true

get '/database' do
  @databases = DB[:pg_database].select(:datname)

  erb :database
end
