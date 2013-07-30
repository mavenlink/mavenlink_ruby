RSpec::Matchers.define :be_an_array_of do |expected, count|
  match do |actual|
    actual.each {|k| k.should be_an_instance_of(expected)}
    actual.count.should eq(count)
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would be an array of #{expected}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not be an array of #{expected}"
  end

  description do
    "be an array of of #{expected}"
  end
end

RSpec::Matchers.define :be_before do |expected|
  match do |actual|
    Time.parse(actual) < Time.parse(expected)
  end

  failure_message_for_should do |actual|
    "expected that #{actual} is before #{expected}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} is not before of #{expected}"
  end

  description do
    "be before #{expected}"
  end
end