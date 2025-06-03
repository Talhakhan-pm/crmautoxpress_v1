# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "callbacks", to: "callbacks.js"
# Manual controller registration - see app/javascript/controllers/index.js
# pin_all_from "app/javascript/controllers", under: "controllers"
