# frozen_string_literal: true

get '/reaction_category' do
  cat = params[:category]

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

  erb :reaction_category
end
