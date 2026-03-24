# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default admin user
User.find_or_create_by!(email: "admin@mine2.io") do |user|
  user.name = "Admin"
  user.password = "74d44e184464605e48c045b94c376ef1"
  user.password_confirmation = "74d44e184464605e48c045b94c376ef1"
  user.role = :admin
end

puts "Seed complete. Admin user: admin@mine2.io"
