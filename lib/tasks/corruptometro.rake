namespace :corruptometro do
  desc "Import contracts from a SECOP II style CSV: bin/rails corruptometro:import[path/to/file.csv]"
  task :import, [ :path ] => :environment do |_task, args|
    abort "usage: bin/rails corruptometro:import[path/to/file.csv]" if args[:path].blank?

    import = ContractImport.new(content: File.read(args[:path]))
    abort import.errors.full_messages.to_sentence unless import.valid?

    result = import.call
    puts "created: #{result.created}, updated: #{result.updated}, rejected: #{result.failures.size}"
    result.failures.each { |failure| puts "  line #{failure.line}: #{failure.messages.to_sentence}" }
  end

  desc "Recompute red flags and risk indexes for every entity"
  task reassess: :environment do
    Entity.find_each(&:reassess!)
    puts "reassessed #{Entity.count} entities"
  end
end
