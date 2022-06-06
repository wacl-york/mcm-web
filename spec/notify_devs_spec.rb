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

  context 'when the error handler is run' do
    # In the test environment, raise_errors is enabled, which allows the exceptions to propogate outside of the app,
    # so rspec can check for them. We can disable this to allow the app's error handler to handle the error instead.
    # We must also pretend we're in a lambda; we only call NotifyDevs when we're in a lambda.
    before do
      allow(FacultyAWS::NotifyDevs).to receive :send_error_warning
      allow(LOGGER).to receive(:error)
      allow(Sinatra::Application).to receive(:in_lambda?).and_return(true)
      allow(Sinatra::Application).to receive(:raise_errors?).and_return(false)
    end

    it 'will try to send an error warning' do
      get error_url
      expect(FacultyAWS::NotifyDevs).to have_received(:send_error_warning)
    end
  end

  # This test will check that the setup for disabling raise_errors does not leak into other spec tests.
  context 'when the test runs as normal' do
    it 'will raise the error' do
      expect { get error_url }.to raise_error('Test Error')
    end
  end
end
