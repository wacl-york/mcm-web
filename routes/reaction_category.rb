# frozen_string_literal: true

get '/reaction_category' do
  cat = params[:category]
  reactionid = params[:reactionid].to_i

  @content = if cat.nil?
               '<p>No reaction category specified.</p>'
             else
               fn = DB[:ReactionCategories].where(ReactionCategory: cat).get(:DocumentationFilename)
               if fn.nil?
                 "<p>Unknown reaction category '#{cat}'.</p>"
               else
                 full_fn = File.join('public', 'reaction_categories', fn)
                 File.read(full_fn)
               end
             end

  @rxn = if cat.nil?
           ''
         else
           rxns = DB[:Reactions].where(ReactionID: reactionid).to_hash(:ReactionID)
           if rxns.nil?
             "<p>Unknown reaction id '#{reactionid}'.</p>"
           else
             reactants = DB[:Reactants].where(ReactionID: reactionid).join(:Species,
                                                                           Name: :Species).to_hash_groups(:ReactionID)
             products = DB[:Products].where(ReactionID: reactionid).join(:Species,
                                                                         Name: :Species).to_hash_groups(:ReactionID)
             # Parse reaction into desired format
             {
               ReactionID: reactionid,
               Rate: rxns[reactionid][:Rate],
               Category: rxns[reactionid][:ReactionCategory],
               Products: products[reactionid].map { |x| { Name: x[:Species], Category: x[:SpeciesCategory] } },
               Reactants: reactants[reactionid].map { |x| { Name: x[:Species], Category: x[:SpeciesCategory] } }
             }
           end
         end
  erb :reaction_category
end
