# frozen_string_literal: true

describe MCM::Search::Basic do
  describe '.find_species' do
    context 'with C5H8' do
      let(:res) { described_class.find_species('C5H8', 17).all }

      it 'only returns 1 value' do
        expect(res.length).to be(1)
      end

      it 'has the expected attributes' do
        expect(res[0].keys).to eq(%i[Name Synonym SearchField score_offset])
      end

      it 'returns C5H8' do
        expect(res[0][:Name]).to eq('C5H8')
      end
    end

    context 'with C2H4' do
      let(:res) { described_class.find_species('C2H4', 17).all }

      it 'returns 16 values' do
        expect(res.length).to be(16)
      end

      it 'has the expected attributes' do
        expect(res[0].keys).to eq(%i[Name Synonym SearchField score_offset])
      end
    end
  end

  describe '.find_synonym' do
    context 'with ethane' do
      let(:res) { described_class.find_synonym('ethane').all }

      it 'finds 659 values' do
        expect(res.length).to be(659)
      end
    end
  end

  describe '.find_smiles' do
    context 'with CC' do
      let(:res) { described_class.find_smiles('CC', 17).all }

      it 'returns 4951 matches for a CC bond' do
        expect(res.length).to be(4951)
      end
    end

    context 'with a Smiles pattern with 1 match' do
      let(:res) { described_class.find_smiles('CC(=C)C(CO[O])O', 17).all }

      it 'returns 1 match' do
        expect(res.length).to be(1)
      end

      it 'returns the correct match' do
        expect(res[0][:Name]).to eq('ISOP34O2')
      end
    end
  end

  describe 'find_inchi' do
    context 'without the InChI prefix' do
      let(:res) { described_class.find_inchi('foo', 17).all }

      it 'returns 0 matches' do
        expect(res.length).to be(0)
      end
    end

    context 'with just the InChI prefix' do
      let(:res) { described_class.find_inchi('InCHi=1S/', 17).all }

      it 'returns 5809 matches' do
        expect(res.length).to be(5809)
      end
    end

    context 'with C2H4/ (trailing slash)' do
      let(:res) { described_class.find_inchi('InChI=1S/C2H4/', 17).all }

      it 'returns just 1 match' do
        expect(res.length).to be(1)
      end

      it 'returns C2H4' do
        expect(res[0][:Name]).to eq('C2H4')
      end
    end

    context 'with C2H4 (no trailing slash)' do
      let(:res) { described_class.find_inchi('InChI=1S/C2H4', 17).all }

      it 'returns 54 matches' do
        expect(res.length).to be(54)
      end
    end
  end

  describe '.search' do
    context 'with C2H4' do
      let(:res) { described_class.search('C2H4', 'MCM').all }

      it 'returns 14 matches' do
        expect(res.length).to be(14)
      end

      it 'returns C2H4 first' do
        expect(res[0][:Name]).to eq('C2H4')
      end
    end

    context 'with methane' do
      let(:res) { described_class.search('methane', 'MCM').all }

      it 'returns CH4 first' do
        expect(res[0][:Name]).to eq('CH4')
      end
    end

    context 'with ethane' do
      let(:res) { described_class.search('ethane', 'MCM').all }

      it 'returns 102 matches' do
        expect(res.length).to be(102)
      end

      it 'returns C2H6 first' do
        expect(res[0][:Name]).to eq('C2H6')
      end
    end

    context 'with methanol' do
      let(:res) { described_class.search('methanol', 'MCM').all }

      it 'returns CH3OH first' do
        expect(res[0][:Name]).to eq('CH3OH')
      end
    end

    context 'with InChI=1S/C5H12O2' do
      let(:res) { described_class.search('InChI=1S/C5H12O2', 'MCM').all }

      it 'returns 24 results with the C2H12O2 group' do
        expect(res.length).to be(24)
      end
    end

    context 'with CC' do
      let(:res) { described_class.search('CC', 'MCM').all }

      it 'returns C2H6 first (from smiles)' do
        expect(res[0][:Name]).to eq('C2H6')
      end

      it 'returns 5027 results' do
        expect(res.length).to be(5027)
      end
    end
  end
end
