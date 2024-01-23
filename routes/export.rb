# frozen_string_literal: true

get '/:mechanism/export' do
  @error = params[:error].nil? ? false : params[:error]
  erb :export
end

# rubocop:disable Metrics/BlockLength
get '/:mechanism/export/download' do
  params[:selected] = [] if params[:selected].nil?

  #------------------- Submechanism
  submech_rxns = MCM::Database.get_submechanism(params[:selected], params[:inorganic], @mechanism)
  # Ensure we have at least 1 reaction in sub-mechanism
  unless submech_rxns.count.positive?
    status 404
    redirect "/#{params[:mechanism]}/export?error=true"
  end

  #------------------- Species
  submech_species = MCM::Database.get_species_involved_in_reactions(submech_rxns)
  peroxies = submech_species
             .where(PeroxyRadical: true)
  missing_peroxies = submech_species
                     .where(PeroxyRadical: nil)

  #------------------- Tokenized Rates
  # Firstly find all tokens directly used in this submechanism
  used_tokens = MCM::Database.get_rate_tokens_used_in_submechanism(submech_rxns)
  # And then travese the tree of tokenized rates to find their children
  # so they are fully specified
  complex_rates = MCM::Database.traverse_complex_rates(used_tokens)

  #------------------- Photolysis Rates
  # Find all photolysis rates used in the submechanism
  photo_rates = MCM::Database.get_photolysis_rates_used_in_submechanism(submech_rxns)

  #------------------- Export
  citation_file = File.open("#{settings.public_folder}/citation.txt")
  citation = citation_file.readlines.map(&:chomp)

  exporter = MCM::Export::Factory.exporter_factory(params[:format])
  content_type exporter.class::CONTENT_TYPE
  attachment exporter.class::FILE_NAME
  exporter.export(
    submech_species.select(:Name),
    submech_rxns,
    complex_rates,
    photo_rates,
    params[:selected],
    missing_peroxies.select(:Name),
    peroxies.select(:Name),
    citation,
    params[:generic]
  )
end
# rubocop:enable Metrics/BlockLength

get '/:mechanism/export/kpp_constants' do
  content_type 'text/plain'
  filename = 'constants_mcm.f90'
  attachment filename
  MCM::Export::KPP.new.constants_file(params[:mechanism])
end
