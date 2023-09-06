# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
get '/:mechanism/?' do
  @mechanism_details = DB[:Mechanisms]
                       .where(Mechanism: params[:mechanism])
                       .first
  @n_species = DB[:SpeciesMechanisms]
               .where(Mechanism: params[:mechanism])
               .count
  @n_reactions = DB[:Reactions]
                 .where(Mechanism: params[:mechanism])
                 .count

  @institutions = case params[:mechanism]
                  when 'MCM'
                    [
                      {
                        url: 'https://www.york.ac.uk/',
                        logo: '/static/logos/uoy_black.svg',
                        alt: 'University of York logo'
                      },
                      {
                        url: 'https://ncas.ac.uk/',
                        logo: '/static/logos/ncas_colour.png',
                        alt: 'NCAS logo'
                      },
                      {
                        url: 'https://www.leeds.ac.uk/',
                        logo: '/static/logos/uol_black.svg',
                        alt: 'University of Leeds logo'
                      }
                    ]
                  when 'CRI'
                    [
                      {
                        url: 'https://www.york.ac.uk/',
                        logo: '/static/logos/uoy_black.svg',
                        alt: 'University of York logo'
                      },
                      {
                        url: 'https://ncas.ac.uk/',
                        logo: '/static/logos/ncas_colour.png',
                        alt: 'NCAS logo'
                      },
                      {
                        url: 'https://www.bristol.ac.uk/',
                        logo: '/static/logos/bristol_colour.png',
                        alt: 'University of Bristol logo'
                      },
                      {
                        url: 'https://www.leeds.ac.uk/',
                        logo: '/static/logos/uol_black.svg',
                        alt: 'University of Leeds logo'
                      }
                    ]
                  end

  # Mechanism-specific content
  fn = File.join('public', 'static', params[:mechanism], 'home.html')
  @content = File.file?(fn) ? File.read(fn) : "<h1>Error</h1><p>Unknown page '#{fn}'.</p>"

  erb :home
end
# rubocop:enable Metrics/BlockLength
