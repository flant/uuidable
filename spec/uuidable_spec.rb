require 'spec_helper'

describe Uuidable do
  it 'has a version number' do
    expect(Uuidable::VERSION).not_to be nil
  end
end
