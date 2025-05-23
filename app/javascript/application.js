// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./callbacks"

// Simple test to verify Turbo is loaded
console.log("Turbo loaded:", window.Turbo ? "yes" : "no")
