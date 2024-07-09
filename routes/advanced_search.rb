# frozen_string_literal: true

get '/:mechanism/advanced_search' do
  @error = params[:error].nil? ? false : params[:error]
  @title = "#{params[:mechanism]} - Advanced search"
  erb :advanced_search
end