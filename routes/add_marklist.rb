# frozen_string_literal: true

post '/add_marklist/:id' do
  session[:mark_list] = [] if session[:mark_list].nil?
  session[:mark_list].append(:id)

  redirect back
end
