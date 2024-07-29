# frozen_string_literal: true

get '/:mechanism/advanced_search' do
  q = params[:q]
  @species = if q.nil?
               nil
             else
               MCM::Search::Advanced.search(q, @mechanism)
             end

  @title = "#{params[:mechanism]} - Advanced search"
  erb :advanced_search
end
