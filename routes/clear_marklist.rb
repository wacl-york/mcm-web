# frozen_string_literal: true

post '/clear_marklist' do
  session[:mark_list] = Set[]
  redirect back
end
