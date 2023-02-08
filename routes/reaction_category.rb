# frozen_string_literal: true

get '/reaction_category' do
  cat = params[:category]
  reactionid = params[:reactionid]

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
           rxn = DB[:ReactionsWide].where(ReactionId: reactionid)
           if fn.nil?
             "<p>Unknown reaction id '#{reactionid}'.</p>"
           else
             rxn.map { |row| "#{row[:Reaction]} : #{row[:Rate]}" }.join
           end
         end

  erb :reaction_category
end
