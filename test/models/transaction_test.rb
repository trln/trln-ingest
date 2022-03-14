require 'test_helper'

class TransactionTest < ActiveSupport::TestCase

	setup do 
    @user = User.create(email:'ncsu@example.com', approved: true)
		record = { id: "TRLN123456789", title_main: "nothing" }
		@record_file = Tempfile.new(["add-spofford-test", ".json"]).path
		File.open(@record_file, "w") do |f|
			f.write(record.to_json)
		end
	end

  test 'stash_directory does not mutate over time' do
  	t = Transaction.create(owner: 'ncsu', user: @user, files: [@record_file])
  	t.stash!
  	t.save!
  	orig_stashdir = t.stash_directory
  	Timecop.freeze(Date.today + 2) do
  		tn = Transaction.find(t.id)
  		assert tn.stash_directory == orig_stashdir
  		t2 = Transaction.create(owner: 'ncsu', files: [@record_file])
  		assert t2.stash_directory != orig_stashdir
  	end
  end
end
