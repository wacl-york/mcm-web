# frozen_string_literal: true

get '/inorganic' do
  @cat = params[:category]

  @rxns = if @cat.nil?
            []
          else
            ids = DB[:Reactions].where(InorganicReactionCategory: @cat).map(:ReactionID)
            puts "IDS: #{ids}"
            if ids.nil?
              []
            else
              read_reaction(ids)
            end
          end
  erb :inorganic
end
