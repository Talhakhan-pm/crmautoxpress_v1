# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create sample callbacks
AgentCallback.create!([
  {
    customer_name: "Joe",
    phone_number: "(817) 489-4064",
    car_make_model: "Ford Fusion",
    year: 2007,
    product: "Motor Mounts",
    zip_code: "76107",
    status: "pending",
    follow_up_date: Date.today,
    agent: "Ayesha",
    notes: "Customer interested, waiting for quote"
  },
  {
    customer_name: "Murtaza",
    phone_number: "(301) 943-2129",
    car_make_model: "Ford E150",
    year: 2003,
    product: "Rear Right Door Lock Actuator",
    zip_code: "",
    status: "purchased",
    follow_up_date: Date.yesterday,
    agent: "Murtaza",
    notes: "Customer already purchased elsewhere"
  },
  {
    customer_name: "Jerry Steinbach",
    phone_number: "(320) 522-8169",
    car_make_model: "Ford Galaxie 500",
    year: 1969,
    product: "Rear Quarter Panels Rocker Panel/Inner Outer LH Front Fender Extension",
    zip_code: "55332",
    status: "later",
    follow_up_date: Date.yesterday,
    agent: "Murtaza",
    notes: "Call back next week"
  }
])
