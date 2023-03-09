# frozen_string_literal: true

get '/browse' do
  @categories = DB[:FrontPageSpecies]
                .join(:Species, Name: :Species)
                .to_hash_groups(:CompoundClass, %i[Species HumanReadable Inchi])
  erb :browse
end
