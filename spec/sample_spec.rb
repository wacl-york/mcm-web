# frozen_string_literal: true

RSpec.describe 'Sample Spec Tests' do
  describe 'the index page' do
    before do
      visit '/'
    end

    it 'contains a greeting' do
      expect(page).to have_text 'Welcome'
    end

    it 'contains a link to itself' do
      expect(page).to have_link href: %r{/}
    end
  end
end
