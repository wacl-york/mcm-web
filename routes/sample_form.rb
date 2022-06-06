# frozen_string_literal: true

get '/sample-form' do
  erb :sample_form
end

form_validator :sample_form do
  param :name, String, required: true
  param :day, Date, required: true, message: 'Must provide a Date'
end

post '/sample-form', validate_form: :sample_form do
  flash_message "Set up \"#{params[:name]}\" on #{params[:day]}.", type: :success
  redirect '/'
end
