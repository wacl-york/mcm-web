# frozen_string_literal: true

post '/add_marklist/:species' do
  session[:mark_list] = [] if session[:mark_list].nil?
  session[:mark_list].append(params[:species])

  redirect back
end
