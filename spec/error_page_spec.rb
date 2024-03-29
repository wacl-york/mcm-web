# frozen_string_literal: true

RSpec.describe 'Error Pages' do
  before do
    local_error = error
    # This will leak into other specs, unfortunately.
    # Check that error_url is set to something that doesn't clash with any routes in your app.
    # NB: Have had to prepend these routes with /MCM otherwise get the 302 redirect to add the missing mechanism
    app.get error_url do
      raise local_error, 'Custom Message'
    end
  end

  context 'with 404 errors' do
    let(:error) { Sinatra::HTTPStatus::NotFound }
    let(:error_url) { '/MCM/http-error-404' }

    it 'returns the correct status' do
      get error_url
      expect(last_response).to be_not_found
    end

    it 'shows the correct error page' do
      visit error_url
      expect(page).to have_text 'Sorry, page not found'
    end

    it 'shows the status code' do
      visit error_url
      expect(page).to have_text 'Error code: 404'
    end

    it 'shows the custom message' do
      visit error_url
      expect(page).to have_text 'Custom Message'
    end
  end

  context 'with 403 errors' do
    let(:error) { Sinatra::HTTPStatus::Forbidden }
    let(:error_url) { '/MCM/http-error-403' }

    it 'returns the correct status' do
      get error_url
      expect(last_response).to be_forbidden
    end

    it 'shows the correct error page' do
      visit error_url
      expect(page).to have_text 'Access Denied'
    end

    it 'shows the status code' do
      visit error_url
      expect(page).to have_text 'Error code: 403'
    end

    it 'shows the custom message' do
      visit error_url
      expect(page).to have_text 'Custom Message'
    end
  end

  context 'with 5xx errors' do
    let(:error) { Sinatra::HTTPStatus::InternalServerError }
    let(:error_url) { '/MCM/http-error-500' }

    it 'returns the correct status' do
      get error_url
      expect(last_response).to be_server_error
    end

    it 'shows the correct error page' do
      visit error_url
      expect(page).to have_text 'Whoops, something went wrong'
    end

    it 'shows the status code' do
      visit error_url
      expect(page).to have_text 'Error code: 500'
    end

    it 'shows the custom message' do
      visit error_url
      expect(page).to have_text 'Custom Message'
    end
  end
end
