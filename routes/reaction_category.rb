# frozen_string_literal: true

get '/:mechanism/reaction_category' do
  cat = params[:category]
  mechanism = params[:mechanism]
  reactionid = params[:reactionid].to_i

  @content = if cat.nil?
               '<p>No reaction category specified.</p>'
             else
               fn = DB[:ReactionCategories].where(ReactionCategory: cat,
                                                  Mechanism: mechanism).get(:DocumentationFilename)
               if fn.nil?
                 "<p>Unknown reaction category '#{Rack::Utils.escape_html(cat)}' for mechanism '#{mechanism}'.</p>"
               else
                 full_fn = File.join('public', 'static', mechanism, 'reaction_categories', fn)
                 File.file?(full_fn) ? File.read(full_fn) : "<p>Unable to locate static file '#{full_fn}'.</p>"
               end
             end

  @rxn = if cat.nil?
           ''
         else
           # read_reaction accepts and returns a list, so we can just drop it to the first value
           MCM::Database.get_reaction(Array(reactionid))[0]
         end
  erb :reaction_category
end
