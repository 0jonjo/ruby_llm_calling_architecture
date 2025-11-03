#!/usr/bin/env ruby
# Demo: LLM Function Calling with Travel Tools
# This script demonstrates how LLMs automatically use tools to answer questions

require_relative 'tools/weather_tool'
require_relative 'tools/destination_search_tool'
require_relative 'tools/itinerary_builder_tool'
require 'json'

puts "=" * 80
puts "🌍 Travel Planning Assistant with LLM Function Calling"
puts "=" * 80
puts
puts "This demo shows how LLMs can automatically use tools to answer questions."
puts "The key concept: You give the LLM access to tools, and it decides when to use them!"
puts

# Initialize tools
weather_tool = WeatherTool.new
destination_tool = DestinationSearchTool.new
itinerary_tool = ItineraryBuilderTool.new

puts "📦 Available Tools:"
puts "  1. WeatherTool - Get current weather for cities"
puts "  2. DestinationSearchTool - Find destinations with SkyTraveler pass tiers"
puts "  3. ItineraryBuilderTool - Create day-by-day itineraries"
puts

# Example 1: Simple tool execution (direct call)
puts "-" * 80
puts "Example 1: Direct Tool Execution (Understanding the Building Blocks)"
puts "-" * 80
puts
puts "Before we see the LLM magic, let's understand what tools do:"
puts

puts "🌤️  WeatherTool.execute(city: 'Paris'):"
weather_result = weather_tool.execute(city: "Paris")
puts JSON.pretty_generate(weather_result)

puts "\n🗺️  DestinationSearchTool.execute(pass_tier: 'gold', query: 'beach'):"
destination_result = destination_tool.execute(pass_tier: "gold", query: "beach", limit: 3)
puts JSON.pretty_generate(destination_result)

# Example 2: Tool with structured output (Halt Pattern)
puts "\n" + "-" * 80
puts "Example 2: Structured Data Extraction (Halt Pattern)"
puts "-" * 80
puts
puts "Some tools return structured data without LLM synthesis:"
puts

puts "📅 ItineraryBuilderTool.execute(destination: 'Barcelona', days: 3):"
itinerary_result = itinerary_tool.execute(
  destination: "Barcelona",
  days: 3,
  interests: ["culture", "food"],
  pace: "moderate"
)

if itinerary_result.is_a?(ItineraryBuilderTool::HaltResult)
  puts "✅ Returns HaltResult - Data goes directly to frontend (no LLM synthesis)"
  puts JSON.pretty_generate(itinerary_result.content)
else
  puts JSON.pretty_generate(itinerary_result)
end

# Example 3: How LLM Uses Tools Automatically
puts "\n" + "=" * 80
puts "Example 3: LLM with Function Calling (The Magic!)"
puts "=" * 80
puts
puts "NOW the interesting part: When you give tools to an LLM, it automatically"
puts "decides when to use them based on the user's question!"
puts

# Simulated conversation flow
puts "-" * 40
puts "👤 User: 'What's the weather in Tokyo? Is it good for traveling?'"
puts
puts "🤖 AI thinks: 'User wants weather info. I have WeatherTool. I'll use it!'"
puts "🤖 AI: [Automatically calls WeatherTool(city: 'Tokyo')]"
tokyo_weather = weather_tool.execute(city: "Tokyo")
puts "   Tool returns: #{tokyo_weather[:summary]}"
puts
puts "🤖 AI synthesizes natural response:"
puts "   'The weather in Tokyo is currently #{tokyo_weather[:condition]} "
puts "   with #{tokyo_weather[:temperature_display]}. Humidity is #{tokyo_weather[:humidity]}"
puts "   with winds at #{tokyo_weather[:wind_speed]}. Perfect for traveling!'"
puts
puts "✨ Key Point: YOU didn't tell the AI to use WeatherTool."
puts "   It saw the tool was available and decided to use it automatically!"

# Example 4: Multi-Tool Conversation (Business Rules + Itinerary)
puts "\n" + "=" * 80
puts "Example 4: Multi-Tool Conversation (Automatic Chaining)"
puts "=" * 80
puts
puts "The LLM can chain multiple tools automatically to answer complex questions!"
puts

puts "-" * 40
puts "👤 User: 'I have a Gold pass. Where can I go in winter? Create an itinerary.'"
puts
puts "🤖 AI thinks: 'I need destinations for Gold pass first, then create itinerary!'"
puts

# First tool call
puts "🤖 AI: [Step 1: Calls DestinationSearchTool]"
puts "       Parameters: pass_tier='gold', season='winter'"
winter_destinations = destination_tool.execute(pass_tier: "gold", season: "winter", limit: 2)
puts "   Tool returns: Found #{winter_destinations[:showing]} destinations"

if winter_destinations[:showing] > 0
  puts "   Top result: #{winter_destinations[:results][0][:name]}"
  first_dest = winter_destinations[:results][0][:name]
  puts

  puts "🤖 AI thinks: 'Great! Let me create an itinerary for #{first_dest}...'"
  puts

  # Second tool call (automatic chaining!)
  puts "🤖 AI: [Step 2: Calls ItineraryBuilderTool]"
  puts "       Parameters: destination='#{first_dest}', days=3"
  itinerary = itinerary_tool.execute(
    destination: first_dest,
    days: 3,
    interests: ["culture", "food"],
    pace: "moderate"
  )

  if itinerary.is_a?(ItineraryBuilderTool::HaltResult)
    puts "   Tool returns: Structured 3-day itinerary"
  end
  puts

  puts "🤖 AI synthesizes final response:"
  puts "   'With your Gold pass, #{first_dest} is perfect for winter! I've created"
  puts "   a 3-day itinerary for you. Day 1 includes exploring local culture and"
  puts "   cuisine. Would you like details for each day?'"
  puts
  puts "✨ Key Point: The LLM automatically called TWO tools in sequence!"
  puts "   It figured out the workflow: check pass access → create itinerary"
  puts "   You just asked one question!"
end

# Example 5: When LLM Chooses NOT to Use Tools
puts "\n" + "=" * 80
puts "Example 5: When LLM Chooses NOT to Use Tools"
puts "=" * 80
puts
puts "The LLM is smart enough to know when tools aren't needed:"
puts

puts "-" * 40
puts "👤 User: 'What are the benefits of traveling?'"
puts
puts "🤖 AI thinks: 'This is a general question. I don't need tools for this.'"
puts "🤖 AI responds directly: 'Traveling offers many benefits including..."
puts "   cultural exposure, personal growth, relaxation, and creating memories.'"
puts
puts "✨ Key Point: Tools are OPTIONAL. The LLM only uses them when helpful!"

# Summary
puts "\n" + "=" * 80
puts "🎯 Summary: How LLM Function Calling Works"
puts "=" * 80
puts
puts "1. You Define Tools:"
puts "   - Each tool has a name, description, and parameters"
puts "   - Tools execute and return structured data"
puts
puts "2. You Give Tools to LLM:"
puts "   chat = LLM.chat.with_tools(WeatherTool, DestinationTool, ...)"
puts
puts "3. User Asks Question:"
puts "   response = chat.ask('What\\'s the weather in Paris?')"
puts
puts "4. LLM Decides Automatically:"
puts "   - Should I use a tool? Which one?"
puts "   - What parameters should I pass?"
puts "   - Should I chain multiple tools?"
puts
puts "5. LLM Executes Tool(s):"
puts "   - Calls tool with validated parameters"
puts "   - Receives structured response"
puts
puts "6. LLM Synthesizes Answer:"
puts "   - Combines tool results into natural language"
puts "   - Answers user's original question"
puts
puts "Benefits:"
puts "  ✅ LLM can access current data (weather, destinations, etc.)"
puts "  ✅ LLM can enforce business rules (membership tiers, access control)"
puts "  ✅ LLM can generate structured data (itineraries, schedules)"
puts "  ✅ LLM can take actions (create bookings, send emails)"
puts "  ✅ All automatically - you just define the tools!"
puts
puts "This transforms LLMs from text generators into intelligent agents!"
puts
