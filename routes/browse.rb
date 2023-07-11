# frozen_string_literal: true

get '/:mechanism?/browse/?' do
  # TODO redirect instead?
  @mechanism = params[:mechanism] ? params[:mechanism] : 'mcm'

  @categories = DB[:FrontPageSpecies]
                .join(:Species, Name: :Species)
                .to_hash_groups(:CompoundClass, %i[Species HumanReadable Inchi])
  @inorganic_categories = DB[:InorganicReactionCategories].map(:InorganicReactionCategory)
  @marklist = cookies[:marklist]
  @marklist = @marklist.nil? ? [] : @marklist.split(',')
  erb :browse
end
