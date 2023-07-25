# frozen_string_literal: true

get '/:mechanism/inorganic' do
  @cat = params[:category]

  @rxns = if @cat.nil?
            []
          else
            ids = DB[:Reactions].where(InorganicReactionCategory: @cat).map(:ReactionID)
            if ids.nil?
              []
            else
              read_reaction(ids)
            end
          end
  erb :inorganic
end
