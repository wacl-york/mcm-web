# frozen_string_literal: true

get '/:mechanism/marklist-validate' do
  raw_marklist = request.cookies['marklist']
  raw_species = raw_marklist.split(',')
  this_mechanism = params[:mechanism]
  valid_species = DB[:SpeciesMechanisms]
                  .where(Name: raw_species,
                         Mechanism: this_mechanism)
                  .select_map(:Name)
  content_type :json
  { valid: valid_species }.to_json
end
