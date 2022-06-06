# frozen_string_literal: true

post '/switch-user' do
  raise 'You are not authorised to switch users.' unless AUTH_GROUP == 'admin'

  student = DB[:students].where(username: params[:username])
  raise "No student record for: #{params[:username]}" if student.count.zero?

  @student = student.first
  session.clear
  session[:student] = @student[:username]
  redirect '/'
end
