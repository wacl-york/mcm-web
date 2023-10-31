# frozen_string_literal: true

get '/:mechanism/inorganic' do
  @cat = params[:category]

  @rxns = if @cat.nil?
            []
          else
            ids = DB[:Reactions].where(InorganicReactionCategory: @cat, Mechanism: params[:mechanism]).map(:ReactionID)
            if ids.nil?
              []
            else
              MCM::Database.get_reaction(ids)
            end
          end
  erb :inorganic
end
