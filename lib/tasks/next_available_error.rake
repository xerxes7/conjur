namespace :error_code do
  task :next do
    err_num = 0
    File.foreach('./app/domain/errors.rb') do |line|
      match = line.match(/code: \"CONJ(?<num>[0-9]+)E\"/)
      if match
        err_num = [err_num, match[:num].to_i].max
      end
    end
    puts "The next available error number is #{err_num+1}"
  end
end
