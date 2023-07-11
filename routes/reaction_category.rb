# frozen_string_literal: true

get '/?:mechanism?/reaction_category' do
  @mechanism = params[:mechanism] || settings.DEFAULT_MECHANISM

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
           # read_reaction accepts and returns a list, so we can just drop it to the first value
           read_reaction(Array(reactionid))[0]
         end
  erb :reaction_category
end
