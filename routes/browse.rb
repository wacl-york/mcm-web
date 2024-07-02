# frozen_string_literal: true

get '/:mechanism/browse/?' do
  @categories = DB[:FrontPageSpecies]
                .where(Mechanism: @mechanism)
                .join(:Species, Name: :Species)
                .to_hash_groups(:CompoundClass, %i[Species HumanReadable Smiles])
  @inorganic_categories = DB[:InorganicReactionCategories].map(:InorganicReactionCategory)
  @marklist = cookies[:marklist]
  @marklist = @marklist.nil? ? [] : @marklist.split(',')
  @title = "#{params[:mechanism]} - Browse"
  erb :browse
end
