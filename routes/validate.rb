# frozen_string_literal: true

get '/:mechanism/marklist-validate' do
  raw_marklist = request.cookies['marklist']
  if raw_marklist.nil?
    valid_species = []
  else
    raw_species = raw_marklist.split(',')
    valid_species = DB[:SpeciesMechanisms]
                    .where(Name: raw_species,
                           Mechanism: params[:mechanism])
                    .select_map(:Name)
  end
  content_type :json
  { valid: valid_species }.to_json
end
