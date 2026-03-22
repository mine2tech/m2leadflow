# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default admin user
User.find_or_create_by!(email: "admin@m2leadflow.com") do |user|
  user.name = "Admin"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :admin
end

puts "Seed complete. Admin user: admin@m2leadflow.com / password123"
