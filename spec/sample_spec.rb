# frozen_string_literal: true

RSpec.describe 'Sample Spec Tests' do
  describe 'the index page' do
    include_context 'log in as', 'abc123'

    before do
      visit '/login'
      visit '/'
    end

    it 'contains a greeting' do
      expect(page).to have_text 'Welcome'
    end

    it 'contains a link to itself' do
      expect(page).to have_link href: %r{/}
    end

    it 'displays the currently logged in user' do
      expect(page).to have_text 'abc123'
    end
  end

  describe 'the database page' do
    before do
      visit '/database'
    end

    it 'displays a list of available databases' do
      expect(page).to have_text 'faculty'
    end
  end
end
