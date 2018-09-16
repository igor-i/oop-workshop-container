# frozen_string_literal: true

Bundler.require(:default)

get '/' do
  'Hello world!'
end

get '/ip' do
  Container['ip'].(request.location)
end

get '/weather' do
  Container['weather_by_geo'].(request.location)
end

# container class
class Container
  extend Dry::Container::Mixin
end

Container.register 'ip' do
  Ip.new
end

Container.register 'geo' do
  Geo.new
end

Container.register 'weather' do
  Weather.new
end

Container.register 'weather_by_geo' do
  WeatherByGeo.new(
    Container['geo'],
    Container['weather']
  )
end

# ip class
class Ip
  def call(params)
    params.ip
  end
end

# geo class
class Geo
  # TODO на проде использовать params
  def call(params)
    # results = Geocoder.search('Paris')
    # results.first.coordinates
    params.coordinates
  end
end

# weather class
class Weather
  def call(params)
    ForecastIO.api_key = '0ebc6d81bcc5518b5ec91cad3683c977'
    latitude, longitude = params
    forecast = ForecastIO.forecast(latitude, longitude)
    temperature = (forecast.currently.temperature - 32) * 5 / 9
    "#{temperature.round}, #{forecast.currently.summary}"
  end
end

# weather by geo class
class WeatherByGeo
  attr_reader :geo, :weather

  def initialize(geo, weather)
    @geo = geo
    @weather = weather
  end

  def call(params)
    coordinates = geo.call(params)
    weather.call(coordinates) if coordinates
  end
end
