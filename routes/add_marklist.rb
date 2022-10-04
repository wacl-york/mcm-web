# frozen_string_literal: true

post '/add_marklist/:species' do
  session[:mark_list] = Set[] if session[:mark_list].nil?
  session[:mark_list].add(params[:species])

  redirect back
end
