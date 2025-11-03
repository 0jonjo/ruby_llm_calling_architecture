#!/usr/bin/env ruby
# Travel Itinerary Builder Tool - Creates structured travel itineraries
# This demonstrates the "halt pattern" for structured data extraction

class ItineraryBuilderTool
  # Tool metadata for LLM
  def self.name
    "build_itinerary"
  end

  def self.description
    "Build a structured travel itinerary with daily activities. "\
    "Provide the destination, number of days, and preferences. "\
    "Returns a complete day-by-day itinerary with activities, meals, and tips."
  end

  def self.parameters
    {
      type: "object",
      properties: {
        destination: {
          type: "string",
          description: "The destination city or country"
        },
        days: {
          type: "integer",
          description: "Number of days for the trip (1-14)",
          minimum: 1,
          maximum: 14
        },
        interests: {
          type: "array",
          items: { type: "string" },
          description: "List of interests (e.g., ['culture', 'food', 'nature'])"
        },
        pace: {
          type: "string",
          enum: ["relaxed", "moderate", "packed"],
          description: "Trip pace: relaxed (2-3 activities/day), moderate (4-5), or packed (6+)",
          default: "moderate"
        }
      },
      required: ["destination", "days"]
    }
  end

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

  # Result class to signal halt (immediate return without LLM synthesis)
  class HaltResult
    attr_reader :content

    def initialize(content)
      @content = content
    end
  end

  def execute(destination:, days:, interests: [], pace: "moderate")
    # Validate inputs
    return error_response("Destination cannot be empty") if destination.to_s.strip.empty?

    days = [[days.to_i, 1].max, 14].min
    pace = "moderate" unless ["relaxed", "moderate", "packed"].include?(pace)

    # Build itinerary
    itinerary = build_itinerary(destination, days, interests, pace)

    # Use halt pattern - return structured data immediately
    # This prevents the LLM from synthesizing the data into prose
    halt(itinerary)
  rescue StandardError => e
    error_response("Failed to build itinerary: #{e.message}")
  end

  private

  def build_itinerary(destination, days, interests, pace)
    activities_per_day = case pace
                        when "relaxed" then 3
                        when "moderate" then 4
                        when "packed" then 6
                        else 4
                        end

    itinerary = {
      destination: destination,
      duration: "#{days} #{days == 1 ? 'day' : 'days'}",
      pace: pace,
      interests: interests,
      daily_schedule: []
    }

    # Generate day-by-day itinerary
    days.times do |day_num|
      day = {
        day: day_num + 1,
        title: generate_day_title(destination, day_num, interests),
        activities: generate_activities(destination, day_num, interests, activities_per_day),
        meals: generate_meals(destination, interests),
        tips: generate_tips(destination, day_num)
      }
      itinerary[:daily_schedule] << day
    end

    itinerary[:summary] = generate_summary(destination, days, itinerary[:daily_schedule])

    itinerary
  end

  def generate_day_title(destination, day_num, interests)
    titles = [
      "Arrival & Exploration",
      "Cultural Immersion",
      "Adventure Day",
      "Local Experiences",
      "Hidden Gems",
      "Relaxation & Leisure",
      "Final Exploration & Departure"
    ]

    titles[day_num] || "Day #{day_num + 1} in #{destination}"
  end

  def generate_activities(destination, day_num, interests, count)
    activity_templates = [
      { time: "09:00", name: "Breakfast at local café", duration: "1h" },
      { time: "10:30", name: "Visit main historical site", duration: "2h" },
      { time: "13:00", name: "Lunch at traditional restaurant", duration: "1.5h" },
      { time: "15:00", name: "Explore local market", duration: "2h" },
      { time: "18:00", name: "Sunset viewing point", duration: "1h" },
      { time: "19:30", name: "Dinner & local entertainment", duration: "2h" }
    ]

    activity_templates.take(count).map do |template|
      template.merge(location: "#{destination} - TBD")
    end
  end

  def generate_meals(destination, interests)
    {
      breakfast: "Local café or hotel breakfast",
      lunch: "Traditional #{destination} cuisine",
      dinner: interests.include?("food") ? "Fine dining experience" : "Casual local restaurant"
    }
  end

  def generate_tips(destination, day_num)
    tips = [
      "Book tickets in advance for popular attractions",
      "Wear comfortable walking shoes",
      "Bring a reusable water bottle",
      "Learn a few local phrases",
      "Check opening hours before visiting"
    ]

    tips.sample(2)
  end

  def generate_summary(destination, days, schedule)
    total_activities = schedule.sum { |day| day[:activities].size }

    "A #{days}-day itinerary for #{destination} with #{total_activities} carefully curated activities. "\
    "This itinerary balances sightseeing, cultural experiences, and relaxation time."
  end

  # Halt pattern - return data immediately without LLM synthesis
  def halt(data)
    HaltResult.new({
      status: "success",
      itinerary: data
    })
  end

  def error_response(message)
    {
      status: "error",
      message: message
    }
  end
end

# Example usage (uncomment to test)
# tool = ItineraryBuilderTool.new
# result = tool.execute(
#   destination: "Paris",
#   days: 3,
#   interests: ["culture", "food"],
#   pace: "moderate"
# )
#
# if result.is_a?(ItineraryBuilderTool::HaltResult)
#   puts "HALT RESULT (would be returned directly):"
#   puts JSON.pretty_generate(result.content)
# else
#   puts result.inspect
# end
