# frozen_string_literal: true

get '/:mechanism/advanced_search' do
  @species = if params.size > 1
              MCM::Search::Advanced.search(params, @mechanism)
             else
              nil
             end

  @title = "#{params[:mechanism]} - Advanced search"
  erb :advanced_search
end
