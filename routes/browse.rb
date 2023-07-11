# frozen_string_literal: true

get '/:mechanism?/browse/?' do
  @mechanism = params[:mechanism] || settings.DEFAULT_MECHANISM

  @categories = DB[:FrontPageSpecies]
                .where(Mechanism: @mechanism)
                .join(:Species, Name: :Species)
                .to_hash_groups(:CompoundClass, %i[Species HumanReadable Inchi])
  @inorganic_categories = DB[:InorganicReactionCategories].map(:InorganicReactionCategory)
  @marklist = cookies[:marklist]
  @marklist = @marklist.nil? ? [] : @marklist.split(',')
  erb :browse
end
