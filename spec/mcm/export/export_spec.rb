# frozen_string_literal: true

require 'rubygems/package'

def read_file_from_tar(archive, target)
  reader = Gem::Package::TarReader.new(Zlib::GzipReader.wrap(File.open(archive, 'rb')))
  reader.each do |x|
    return x.read.force_encoding('utf-8') if x.full_name == target
  end
end

def build_url(mechanism, species, format)
  species_formatted = species.map { |x| "selected[]=#{x}" }.join('&')
  "/#{mechanism}/export/download?inorganic=true&generic=true&format=#{format}&#{species_formatted}"
end

describe 'regression test of full mechanism export' do
  let(:mcm_species) { DB[:FrontPageSpecies].where(Mechanism: 'MCM').select_map(:Species) }
  let(:cri_species) { DB[:FrontPageSpecies].where(Mechanism: 'CRI').select_map(:Species) }

  describe 'FACSIMILE format' do
    context 'with the MCM' do
      let(:url) { build_url('MCM', mcm_species, 'facsimile') }
      let(:reference) do
        read_file_from_tar('public/static/MCM/download/mcm_3-3-1.tar.gz',
                           'mcm_3-3-1_unix/mcm_3-3-1_facsimile_complete.fac')
      end

      it 'is equal to the archived mechanism' do
        get url
        expect(last_response.body).to eq(reference)
      end
    end

    context 'with the CRI' do
      let(:url) { build_url('CRI', cri_species, 'facsimile') }
      let(:reference) do
        read_file_from_tar('public/static/CRI/download/cri_2-2.tar.gz', 'cri_2-2_unix/cri_2-2_facsimile_complete.fac')
      end

      it 'is equal to the archived mechanism' do
        get url
        expect(last_response.body).to eq(reference)
      end
    end
  end

  describe 'KPP format' do
    context 'with the MCM' do
      let(:reference) do
        read_file_from_tar('public/static/MCM/download/mcm_3-3-1.tar.gz',
                           'mcm_3-3-1_unix/mcm_3-3-1_kpp_complete.eqn')
      end
      let(:reference_constants) do
        read_file_from_tar('public/static/MCM/download/mcm_3-3-1.tar.gz',
                           'mcm_3-3-1_unix/mcm_3-3-1_kpp_constants_mcm.f90')
      end

      it 'is equal to the archived mechanism' do
        get build_url('MCM', mcm_species, 'kpp')
        expect(last_response.body).to eq(reference)
      end

      it 'has the same constants_mcm.f90' do
        get '/MCM/export/kpp_constants'
        expect(last_response.body).to eq(reference_constants)
      end
    end

    context 'with the CRI' do
      let(:reference) do
        read_file_from_tar('public/static/CRI/download/cri_2-2.tar.gz', 'cri_2-2_unix/cri_2-2_kpp_complete.eqn')
      end
      let(:reference_constants) do
        read_file_from_tar('public/static/CRI/download/cri_2-2.tar.gz',
                           'cri_2-2_unix/cri_2-2_kpp_constants_mcm.f90')
      end

      it 'is equal to the archived mechanism' do
        get build_url('CRI', cri_species, 'kpp')
        expect(last_response.body).to eq(reference)
      end

      it 'has the same constants_mcm.f90' do
        get '/CRI/export/kpp_constants'
        expect(last_response.body).to eq(reference_constants)
      end
    end
  end

  describe 'species list TSV format' do
    context 'with the MCM' do
      let(:url) { build_url('MCM', mcm_species, 'species_tsv') }
      let(:reference) do
        read_file_from_tar('public/static/MCM/download/mcm_3-3-1.tar.gz',
                           'mcm_3-3-1_unix/mcm_3-3-1_species_complete.tsv')
      end

      it 'is equal to the archived species list' do
        get url
        expect(last_response.body).to eq(reference)
      end
    end

    context 'with the CRI' do
      let(:url) { build_url('CRI', cri_species, 'species_tsv') }
      let(:reference) do
        read_file_from_tar('public/static/CRI/download/cri_2-2.tar.gz', 'cri_2-2_unix/cri_2-2_species_complete.tsv')
      end

      it 'is equal to the archived species list' do
        get url
        expect(last_response.body).to eq(reference)
      end
    end
  end
end
