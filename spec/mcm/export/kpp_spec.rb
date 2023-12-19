# frozen_string_literal: true

describe MCM::Export::KPP do
  let(:kpp) { described_class.new }

  describe '.parse_rate_for_kpp' do
    context 'with 5*TEMP' do
      let(:res) { kpp.parse_rate_for_kpp('5*TEMP', {}) }

      it 'adds the dp' do
        expect(res).to eq('5.*TEMP')
      end
    end

    context 'with 1.23D-12*TEMP(300)' do
      let(:res) { kpp.parse_rate_for_kpp('1.23D-12*TEMP(300)', {}) }

      it 'replaces D with E' do
        expect(res).to eq('1.23E-12*TEMP(300.)')
      end
    end

    context 'with 2.3@5' do
      let(:res) { kpp.parse_rate_for_kpp('2.3@5', {}) }

      it 'replaces @ with **' do
        expect(res).to eq('2.3**5.')
      end
    end

    context 'with TEMP(300)*J<17>' do
      let(:res) { kpp.parse_rate_for_kpp('TEMP(300)*J<17>', { 'J<17>' => 'J<34>' }) }

      it 'applies a photolysis mapping' do
        expect(res).to eq('TEMP(300.)*J(34)')
      end
    end

    context 'with 3.84D-12*EXP(533/TEMP)*0.157' do
      let(:res) { kpp.parse_rate_for_kpp('3.84D-12*EXP(533/TEMP)*0.157', {}) }

      it 'correctly applies dps' do
        expect(res).to eq('3.84E-12*EXP(533./TEMP)*0.157')
      end
    end

    context 'with 71.11D-12' do
      let(:res) { kpp.parse_rate_for_kpp('71.11D-12', {}) }

      it 'correctly applies dps' do
        expect(res).to eq('71.11E-12')
      end
    end
  end
end
