#!/usr/bin/env ruby
# Weather Tool - Fetches current weather information
# This demonstrates a simple external API integration with error handling

require 'net/http'
require 'json'
require 'uri'

class WeatherTool
  # Tool metadata for LLM
  def self.name
    "get_current_weather"
  end

  def self.description
    "Get the current weather for a specific city. Use this when users ask about weather conditions, temperature, or forecasts."
  end

  def self.parameters
    {
      type: "object",
      properties: {
        city: {
          type: "string",
          description: "The city name (e.g., 'Paris', 'Tokyo', 'New York')"
        },
        units: {
          type: "string",
          enum: ["celsius", "fahrenheit"],
          description: "Temperature units (default: celsius)",
          default: "celsius"
        }
      },
      required: ["city"]
    }
  end

  # Convert to OpenAI function format
  def self.to_openai
    {
      type: "function",
      function: {
        name: name,
        description: description,
        parameters: parameters
      }
    }
  end

  # Execute the tool
  def execute(city:, units: "celsius")
    # Input validation
    return error_response("City name cannot be empty") if city.to_s.strip.empty?

    # Simulate API call (in real implementation, use OpenWeatherMap, WeatherAPI, etc.)
    weather_data = fetch_weather(city, units)

    if weather_data
      format_success_response(city, weather_data, units)
    else
      {
        status: "no_data",
        message: "Could not find weather data for '#{city}'. Please check the city name.",
        city: city
      }
    end
  rescue StandardError => e
    error_response("Weather service failed: #{e.message}")
  end

  private

  # Simulated weather data (replace with real API in production)
  def fetch_weather(city, units)
    # Mock data for common cities
    weather_database = {
      "paris" => { temp: 18, condition: "Partly Cloudy", humidity: 65, wind: 12 },
      "tokyo" => { temp: 22, condition: "Clear", humidity: 55, wind: 8 },
      "new york" => { temp: 15, condition: "Rainy", humidity: 78, wind: 15 },
      "london" => { temp: 12, condition: "Foggy", humidity: 82, wind: 10 },
      "sydney" => { temp: 25, condition: "Sunny", humidity: 60, wind: 14 },
      "rio de janeiro" => { temp: 28, condition: "Sunny", humidity: 70, wind: 11 },
      "berlin" => { temp: 14, condition: "Overcast", humidity: 68, wind: 13 },
      "dubai" => { temp: 35, condition: "Hot and Sunny", humidity: 45, wind: 9 }
    }

    data = weather_database[city.downcase]
    return nil unless data

    # Convert temperature if needed
    if units == "fahrenheit"
      data[:temp] = (data[:temp] * 9.0 / 5.0 + 32).round
    end

    data
  end

  def format_success_response(city, data, units)
    temp_unit = units == "fahrenheit" ? "°F" : "°C"

    {
      status: "success",
      city: city,
      temperature: data[:temp],
      temperature_display: "#{data[:temp]}#{temp_unit}",
      condition: data[:condition],
      humidity: "#{data[:humidity]}%",
      wind_speed: "#{data[:wind]} km/h",
      summary: "The weather in #{city} is #{data[:condition].downcase} with a temperature of #{data[:temp]}#{temp_unit}."
    }
  end

  def error_response(message)
    {
      status: "error",
      message: message
    }
  end
end

# Example usage (uncomment to test)
# tool = WeatherTool.new
# puts tool.execute(city: "Paris").inspect
# puts tool.execute(city: "Tokyo", units: "fahrenheit").inspect
# puts tool.execute(city: "Unknown City").inspect
