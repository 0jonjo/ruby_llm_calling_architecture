#!/usr/bin/env ruby
# Load this file in IRB to chat with LLM that uses tools automatically
#
# Usage:
#   irb -r bundler/setup -r dotenv/load -r ./chat.rb
#
# Then:
#   ask("What's the weather in Paris?")
#   ask("Where can I go with my Gold pass?")
#   ask("Create a 3-day itinerary for Tokyo")

require 'ruby_llm'
require_relative 'tools/weather_tool'
require_relative 'tools/destination_search_tool'
require_relative 'tools/itinerary_builder_tool'

# Wrapper tools for ruby_llm compatibility
class RubyLLMWeatherTool < RubyLLM::Tool
  description "Get the current weather for a specific city"
  param :city, type: 'string', desc: "City name (e.g., 'Paris', 'Tokyo')", required: true
  param :units, type: 'string', desc: "Temperature units: 'celsius' or 'fahrenheit'", required: false

  def execute(city:, units: 'celsius')
    WeatherTool.new.execute(city: city, units: units)
  end
end

class RubyLLMDestinationTool < RubyLLM::Tool
  description "Search for SkyTraveler pass destinations. Check which destinations you can visit based on your membership pass tier (Silver, Gold, or Platinum). Silver unlocks regional destinations, Gold adds continental destinations, Platinum unlocks worldwide luxury destinations."
  param :pass_tier, type: 'string', desc: "Your SkyTraveler pass tier: 'silver', 'gold', or 'platinum'", required: true
  param :query, type: 'string', desc: "What you're looking for (e.g., 'beach', 'culture', 'adventure')", required: false
  param :season, type: 'string', desc: "Preferred season: 'spring', 'summer', 'fall', 'winter'", required: false
  param :limit, type: 'integer', desc: "Max number of results", required: false

  def execute(pass_tier:, query: 'any', season: 'any', limit: 10)
    DestinationSearchTool.new.execute(pass_tier: pass_tier, query: query, season: season, limit: limit)
  end
end

class RubyLLMItineraryTool < RubyLLM::Tool
  description "Create a detailed day-by-day travel itinerary for a destination"
  param :destination, type: 'string', desc: "Destination city", required: true
  param :days, type: 'integer', desc: "Number of days", required: true
  param :pace, type: 'string', desc: "Travel pace: 'relaxed', 'moderate', or 'fast'", required: false

  def execute(destination:, days:, pace: 'moderate')
    result = ItineraryBuilderTool.new.execute(
      destination: destination,
      days: days,
      interests: ['culture', 'food'],  # Default interests
      pace: pace
    )

    # Handle HaltResult
    if result.is_a?(ItineraryBuilderTool::HaltResult)
      halt(result.content.to_json)
    else
      result
    end
  end
end

# Configure
RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.gemini_api_key = ENV['GEMINI_API_KEY']
end

# Create chat with tools
$chat = RubyLLM.chat.with_tools(
  RubyLLMWeatherTool.new,
  RubyLLMDestinationTool.new,
  RubyLLMItineraryTool.new
)

# Track tool usage
$last_tool_used = nil

# Wrap tools to track usage
[RubyLLMWeatherTool, RubyLLMDestinationTool, RubyLLMItineraryTool].each do |klass|
  klass.class_eval do
    alias_method :original_execute, :execute

    define_method(:execute) do |**args|
      $last_tool_used = self.class.name.gsub('RubyLLM', '').gsub('Tool', '')
      original_execute(**args)
    end
  end
end

# Simple helper
def ask(message)
  puts "\n💬 You: #{message}"

  $last_tool_used = nil
  response = $chat.ask(message)

  if $last_tool_used
    puts "🔧 LLM used tool: #{$last_tool_used}"
  else
    puts "💭 LLM answered directly (no tools needed)"
  end

  puts "🤖 AI: #{response.content}\n\n"
  response
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  puts "   Make sure OPENAI_API_KEY or GEMINI_API_KEY is set in .env"
  nil
end

# Welcome
if ENV['OPENAI_API_KEY'] || ENV['GEMINI_API_KEY']
  puts "\n✅ Ready! Try: ask(\"What's the weather in Paris?\")\n\n"
else
  puts "\n⚠️  No API key found. Set OPENAI_API_KEY or GEMINI_API_KEY in .env file\n\n"
end
