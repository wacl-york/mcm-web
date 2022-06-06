# frozen_string_literal: true

RSpec.describe 'Check Europe/London is in use' do
  subject { time.localtime.strftime '%d/%m/%Y %H:%M' }

  context 'with a time during daylight savings time' do
    let(:time) { Time.parse '2022-03-28T10:00:00+01:00' }

    it { is_expected.to eq '28/03/2022 10:00' }
  end

  context 'with a UTC time during daylight savings time' do
    let(:time) { Time.parse '2022-03-28T10:00:00+00:00' }

    it { is_expected.to eq '28/03/2022 11:00' }
  end

  context 'with a UTC time outside of daylight savings time' do
    let(:time) { Time.parse '2022-03-21T10:00:00+00:00' }

    it { is_expected.to eq '21/03/2022 10:00' }
  end

  context 'with an offset time outside of daylight savings time' do
    let(:time) { Time.parse '2022-03-21T10:00:00+01:00' }

    it { is_expected.to eq '21/03/2022 09:00' }
  end
end
