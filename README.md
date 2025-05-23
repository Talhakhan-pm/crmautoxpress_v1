# AutoXpress CRM

This is a Ruby on Rails application for managing automotive customer callbacks and CRM operations.

## Turbo Frames Implementation Guide

### Complete Step-by-Step Instructions for Adding Turbo Frames to Any Model

Follow these exact steps to implement seamless navigation with Turbo Frames:

#### 1. Install Turbo Rails Properly
```bash
bin/rails turbo:install
```
This command will:
- Add turbo-rails to importmap.rb
- Update application.js to import turbo

#### 2. Verify Turbo Loading in JavaScript
Add this to `app/javascript/application.js`:
```javascript
import "@hotwired/turbo-rails"
import "./callbacks"

// Verify Turbo is loaded
console.log("Turbo loaded:", window.Turbo ? "yes" : "no")
```

#### 3. Index View Setup
Wrap the main content in a turbo frame and add data attributes to navigation links:

```erb
<!-- app/views/callbacks/index.html.erb -->
<main class="main-content">
    <%= turbo_frame_tag "main_content" do %>
        <header class="main-header">
            <!-- Header content -->
            <div class="header-actions">
                <%= link_to new_callback_path, class: "btn btn-primary", data: { turbo_frame: "main_content" } do %>
                    <i class="fas fa-plus"></i>
                    Add Callback
                <% end %>
            </div>
        </header>
        
        <!-- Rest of your index content (tables, lists, etc.) -->
        
    <% end %>
</main>
```

#### 4. New/Edit View Setup
Use the same turbo frame ID and add data attributes to back/cancel links:

```erb
<!-- app/views/callbacks/new.html.erb -->
<main class="main-content">
    <%= turbo_frame_tag "main_content" do %>
        <header class="main-header">
            <!-- Header content -->
            <div class="header-actions">
                <%= link_to callbacks_path, class: "btn btn-secondary", data: { turbo_frame: "main_content" } do %>
                    <i class="fas fa-arrow-left"></i>
                    Back to Callbacks
                <% end %>
            </div>
        </header>
        
        <div class="content-card">
            <%= form_with model: @callback, url: callbacks_path, local: true, class: "callback-form" do |form| %>
                <!-- Form fields -->
                
                <div class="form-actions">
                    <%= link_to "Cancel", callbacks_path, class: "btn btn-secondary", data: { turbo_frame: "main_content" } %>
                    <%= form.submit "Create Callback", class: "btn btn-primary" %>
                </div>
            <% end %>
        </div>
    <% end %>
</main>
```

#### 5. Form Configuration Rules
- **ALWAYS use `local: true`** in `form_with` for turbo frames to work properly
- **DO NOT use `local: false`** - this breaks turbo frame behavior
- **DO NOT add `data: { turbo_frame: "frame_id" }`** to the form itself - forms automatically submit within their containing frame

#### 6. Controller Requirements
No special changes needed in the controller. Standard redirect behavior works:

```ruby
def create
  @callback = AgentCallback.new(callback_params)
  
  if @callback.save
    redirect_to callbacks_path, notice: 'Callback was successfully created.'
  else
    render :new, status: :unprocessable_entity
  end
end
```

#### 7. Critical Requirements Checklist
- [ ] `bin/rails turbo:install` has been run
- [ ] Browser console shows "Turbo loaded: yes"
- [ ] Both views use identical `turbo_frame_tag` ID (e.g., "main_content")
- [ ] Navigation links include `data: { turbo_frame: "main_content" }`
- [ ] Forms use `local: true` (not `local: false`)
- [ ] Forms do NOT have `data: { turbo_frame: "frame_id" }` attribute

#### 8. Troubleshooting
If turbo frames aren't working:

1. **Check console**: Should show "Turbo loaded: yes"
2. **Check Network tab**: Requests should include `Turbo-Frame: main_content` header
3. **Verify frame IDs**: Must be identical in both views
4. **Check form config**: Must use `local: true`
5. **Restart server**: After turbo installation

### Example for Other Models
To implement this pattern for any other model (e.g., `products`):

1. Replace `callbacks` with your model name in paths
2. Replace `@callback` with your instance variable
3. Use the same turbo frame ID across related views
4. Follow the exact form configuration rules above

## Ruby version
* Ruby 3.2.2

## System dependencies
* Redis server

## Getting Started
* `bundle install`
* `rails db:create db:migrate db:seed`
* `rails server`
