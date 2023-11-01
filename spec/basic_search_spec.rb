# frozen_string_literal: true

RSpec.describe 'Basic Search Tests' do
  describe 'find_species' do
    it 'contains MCM' do
      expect(page).to have_text 'MCM'
    end
  end
end
