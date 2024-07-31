# frozen_string_literal: true

get '/:mechanism/advanced_search' do
  @species = (MCM::Search::Advanced.search(params, @mechanism) if params.size > 1)

  @title = "#{params[:mechanism]} - Advanced search"
  erb :advanced_search
end
