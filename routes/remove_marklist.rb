# frozen_string_literal: true

post '/remove_marklist' do
  session[:mark_list] = session[:mark_list] - params[:selected] unless params[:selected].nil?
  redirect back
end
