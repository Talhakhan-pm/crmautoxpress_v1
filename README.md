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
No special changes needed in the controller. Standard redirect and validation behavior works:

```ruby
def create
  @callback = AgentCallback.new(callback_params)
  
  if @callback.save
    redirect_to callbacks_path, notice: 'Callback was successfully created.'
  else
    render :new, status: :unprocessable_entity  # This renders errors within turbo frame
  end
end
```

#### 7. Validation Error Handling
Add error display to your form view:

```erb
<% if @callback.errors.any? %>
    <div class="alert alert-danger">
        <h4><%= pluralize(@callback.errors.count, "error") %> prohibited this callback from being saved:</h4>
        <ul>
            <% @callback.errors.full_messages.each do |message| %>
                <li><%= message %></li>
            <% end %>
        </ul>
    </div>
<% end %>
```

Add CSS for error styling:
```scss
.alert-danger {
    color: #721c24;
    background-color: #f8d7da;
    border-color: #f5c6cb;
    padding: 16px;
    margin-bottom: 24px;
    border-radius: 8px;
}

.field_with_errors input,
.field_with_errors select,
.field_with_errors textarea {
    border-color: #dc3545 !important;
    box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25) !important;
}
```

#### 8. Critical Requirements Checklist
- [ ] `bin/rails turbo:install` has been run
- [ ] Browser console shows "Turbo loaded: yes"
- [ ] Both views use identical `turbo_frame_tag` ID (e.g., "main_content")
- [ ] Navigation links include `data: { turbo_frame: "main_content" }`
- [ ] Forms use `local: true` (not `local: false`)
- [ ] Forms do NOT have `data: { turbo_frame: "frame_id" }` attribute
- [ ] Error handling added to form views for validation failures
- [ ] CSS styling added for error alerts and field highlighting

#### 9. Troubleshooting
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

## Live Broadcasting Implementation Guide

### Real-time Updates with Turbo Streams

The callbacks table now supports live broadcasting - users will see real-time updates when callbacks are created, updated, or deleted across all browser sessions.

#### How It Works

1. **Model Broadcasting**: The `AgentCallback` model automatically broadcasts changes:
```ruby
# app/models/agent_callback.rb
after_create_commit { broadcast_prepend_to "callbacks", target: "callbacks" }
after_update_commit { broadcast_replace_to "callbacks" }
after_destroy_commit { broadcast_remove_to "callbacks" }
```

2. **View Subscription**: The index view subscribes to live updates:
```erb
<!-- app/views/callbacks/index.html.erb -->
<%= turbo_stream_from "callbacks" %>
<tbody id="callbacks">
  <% @callbacks.each do |callback| %>
    <tr id="<%= dom_id(callback) %>">
      <!-- callback data -->
    </tr>
  <% end %>
</tbody>
```

3. **Partial Template**: Individual callback rows are rendered using:
```erb
<!-- app/views/agent_callbacks/_agent_callback.html.erb -->
<tr id="<%= dom_id(agent_callback) %>">
  <!-- callback row content -->
</tr>
```

4. **Controller Support**: Controllers handle turbo stream responses:
```ruby
def create
  respond_to do |format|
    if @callback.save
      format.html { redirect_to callbacks_path, notice: 'Callback was successfully created.' }
      format.turbo_stream { redirect_to callbacks_path, notice: 'Callback was successfully created.' }
    else
      format.html { render :new, status: :unprocessable_entity }
      format.turbo_stream { render :new, status: :unprocessable_entity }
    end
  end
end
```

#### Live Update Behaviors

- **New Callback Created**: Appears at the top of the table instantly
- **Callback Updated**: Row updates with new data in real-time
- **Callback Deleted**: Row disappears immediately

#### Requirements for Live Broadcasting

1. **Redis Server**: Must be running for ActionCable
   ```bash
   redis-server
   ```

2. **Cable Configuration**: Already set up in `config/cable.yml`:
   ```yaml
   development:
     adapter: async
   production:
     adapter: redis
   ```

3. **ActionCable Integration**: No additional JavaScript imports needed - Turbo Rails handles ActionCable automatically

#### Testing Live Broadcasting

1. Open multiple browser windows to the callbacks index
2. Create/edit/delete a callback in one window
3. Watch the changes appear instantly in all other windows
4. Check browser network tab for WebSocket connections

#### Troubleshooting Live Updates

- **No live updates**: Check if Redis is running
- **WebSocket errors**: Verify ActionCable routes in `config/routes.rb`
- **Updates not appearing**: Ensure `turbo_stream_from "callbacks"` is in the view
- **Wrong target**: Verify `tbody id="callbacks"` matches the broadcast target

## Getting Started
* `bundle install`
* `rails db:create db:migrate db:seed`
* Start Redis: `redis-server`
* `rails server`
