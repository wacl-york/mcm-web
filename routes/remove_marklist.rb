# frozen_string_literal: true

post '/remove_marklist' do
  unless params[:selected].nil?
    session[:mark_list] = session[:mark_list] - params[:selected]
  end
  redirect back
end
