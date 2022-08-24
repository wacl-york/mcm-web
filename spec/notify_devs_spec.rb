# frozen_string_literal: true

RSpec.describe 'Check NotifyDevs is set up correctly' do
  before do
    # This will leak into other specs, unfortunately.
    # Check that error_url is set to something that doesn't clash with any routes in your app.
    app.get error_url do
      raise 'Test Error'
    end
  end

  let(:error_url) { '/test-error' }

  # This test will check that the setup for disabling raise_errors does not leak into other spec tests.
  context 'when the test runs as normal' do
    it 'will raise the error' do
      expect { get error_url }.to raise_error('Test Error')
    end
  end
end
