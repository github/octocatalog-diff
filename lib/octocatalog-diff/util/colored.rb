# frozen_string_literal: true

# Create colorizing methods in the 'String' class, but only if 'colors_enabled'
# has been set.
class String
  COLORS = {
    'red'    => 31,
    'green'  => 32,
    'yellow' => 33,
    'cyan'   => 36
  }.freeze

  COLORS.each do |color, _value|
    define_method(color) do
      @@colors_enabled ? "\e[0;#{COLORS[color]};49m#{self}\e[0m" : self
    end
  end

  def self.colors_enabled=(value)
    @@colors_enabled = value # rubocop:disable Style/ClassVars
  end
end
