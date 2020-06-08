require 'test_helper'

class DirectorateTest < ActiveSupport::TestCase
  test 'blank directorate cannot be saved' do
    directorate = Directorate.new
    refute directorate.save
    directorate.name = 'Directorate name'
    assert directorate.save
  end

  test 'duplicate directorate name cannot be saved' do
    directorate = Directorate.new
    directorate.name = 'Directorate name'
    assert directorate.save
    directorate2 = Directorate.new
    directorate2.name = 'Directorate name'
    refute directorate2.save
  end

end
