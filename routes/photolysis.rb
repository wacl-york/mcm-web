# frozen_string_literal: true

get '/:mechanism/rates/photolysis' do
  @photo_params = DB[:PhotolysisParameters]
                  .exclude(l: nil)
  erb :photolysis
end
