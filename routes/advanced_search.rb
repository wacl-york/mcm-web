# frozen_string_literal: true

get '/:mechanism/advanced_search' do
  q = params[:q]
  puts q
  @species = if q.nil?
               # nil
               MCM::Search::Advanced.search(nil, @mechanism)
             else
               MCM::Search::Advanced.search(q, @mechanism)
             end

  puts "output: #{@species.class}"

  @title = "#{params[:mechanism]} - Advanced search"
  erb :advanced_search
end
