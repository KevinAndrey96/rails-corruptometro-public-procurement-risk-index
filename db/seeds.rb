# Admin account from ADMIN_EMAIL and ADMIN_PASSWORD, so no credential lives in the repository.
password = ENV["ADMIN_PASSWORD"]

if password.present?
  admin = User.find_or_initialize_by(email_address: ENV.fetch("ADMIN_EMAIL", "admin@example.com"))
  admin.update!(password: password, password_confirmation: password)
  puts "Admin account ready for #{admin.email_address}"
else
  puts "ADMIN_PASSWORD is not set, skipping the admin account"
end

# Fictional demo contracts loaded through the same importer the admin area uses.
if ENV.fetch("LOAD_DEMO_DATA", "true") == "true" && Contract.none?
  result = ContractImport.new(content: Rails.root.join("db/samples/contratos_demo.csv").read).call
  puts "Demo data: #{result.created} contracts imported, #{result.failures.size} rows rejected"
end
