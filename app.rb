require 'sinatra'
require 'fog'
require 'dotenv'
Dotenv.load
set :port, 80

preffered_content_types = ['application/octet-stream' , 'audio/ogg']

URL_REGEX = /https:\/\/parrote\.s3\.amazonaws\.com\/uploads\/(?<uuid>[\w-]+)\.ogg/

get '/' do
 'hello world!'
end

get '/nr' do
  ts = Time.now

  url = params['url']

  if not url.nil? and url =~ URL_REGEX

    uuid = URL_REGEX.match(url)['uuid']

    pid = fork do
      # Download recording from s3
      `curl -o #{uuid}.ogg #{url}`
      # NR on white noise
      `sox #{uuid}.ogg #{uuid}-nr.ogg noisered noise_white.noise-profile 0.2`
      # Clean up
      `rm #{uuid}.ogg`

      # Upload NR file
      if upload(uuid)
        # upload successful
        # Send API request to inform server
        reducted(uuid)
      end
    end

    'https://parrote.s3.amazonaws.com/uploads/#{uuid}-nr.ogg'

  else
    'URL is not in an appropriate format'
  end

end

def reducted(uuid)
  # Create a request on rails server
  # find record with uuid
  # change record's status to Reducted
  uri = URI.parse("http://www.loroclip.com/api/v1/records/nr")
  params = {
    :url => 'https://parrote.s3.amazonaws.com/uploads/#{uuid}-nr.ogg',
    :uuid => uuid
  }
  res = Net::HTTP.post_form(uri, params)

end

def upload(filename)

  connection = Fog::Storage.new({
    :provider               => 'AWS',
    :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
    :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'],
  })

  directory = connection.directories.get(ENV['AWS_BUCKET_NAME']);

  file = directory.files.new({
    :key                    => ENV['AWS_BUCKET_NAME'],
    :body                   => File.open(uuid+'-nr.ogg'),
    :public                 => true,
    })

  file.save

end

