# Testing the Return Tracking System

## Prerequisites

1. **Run the database migration** (if not already done):
   ```bash
   rails db:migrate
   ```

2. **Start the Rails server**:
   ```bash
   rails server
   ```

## Complete End-to-End Testing

### Step 1: Create Test Orders with Dispatches

1. Go to `/orders/new` and create a few test orders
2. For each order, create a dispatch and set status to "shipped" or "completed"
3. Make sure the dispatches have `payment_status: 'paid'`

### Step 2: Test Agent Return/Refund UI

1. **Navigate to Orders Index**: Go to `/orders`

2. **Test Card View Dropdown**:
   - Look for orders with shipped/completed dispatches
   - Click the return icon (undo icon) in the action buttons
   - Verify dropdown appears with 4 options:
     - Wrong Product
     - Defective Product
     - Changed Mind  
     - Quality Issues

3. **Test Table View Dropdown**:
   - Switch to table view
   - Click the "Return" button in the Actions column
   - Verify same dropdown options appear

4. **Test Return Request Creation**:
   - Click on "Wrong Product" option
   - Confirm the action when prompted
   - Verify the refund is created

### Step 3: Verify Resolution Center Integration

1. **Navigate to Resolution Center**: Go to `/resolution`

2. **Check for Return Requests**:
   - Look for the refund you just created
   - Verify it shows in "pending_customer_clarification" stage
   - Verify it has return context/indicators

3. **Test Return Management Actions**:
   - Click on a return request item
   - Look for return management options
   - Test return authorization workflow

### Step 4: Test Return Status Workflow

1. **Authorize Return** (as dispatcher):
   - In resolution center, authorize a return request
   - Verify return status changes to "return_authorized"

2. **Generate Return Label**:
   - Test return label generation
   - Verify status changes to "return_label_sent"

3. **Mark Return Shipped**:
   - Test marking return as shipped
   - Verify status changes to "return_shipped"

4. **Mark Return Received**:
   - Test marking return as received
   - Verify status changes to "return_received"

## Expected Behavior

### Return-Eligible Reasons (wrong_product, defective_product, quality_issues):
- **Initial State**: `refund_stage: 'pending_resolution'`
- **Resolution Stage**: `pending_customer_clarification`
- **Return Status**: `return_requested`
- **Order Status**: Should remain unchanged initially
- **Appears in**: Resolution Center for agent/dispatcher action

### Non-Return Reasons (customer_changed_mind):
- **Initial State**: `refund_stage: 'pending_refund'`
- **Return Status**: `no_return_required`
- **Order Status**: Should be cancelled immediately
- **Workflow**: Goes straight to standard refund processing

## Key Files Modified

### UI Components:
- `app/views/orders/_orders_content.html.erb` - Return dropdown UI
- `app/views/resolution/` - Resolution center views with return management

### Backend Logic:
- `app/models/refund.rb` - Return status enum and workflow methods
- `app/controllers/refunds_controller.rb` - Create method for return requests
- `config/routes.rb` - Added create_refund route

### Styling:
- `app/assets/stylesheets/orders.scss` - Return dropdown styles
- `app/assets/stylesheets/dispatches.scss` - Return management styles
- `app/assets/stylesheets/resolution.scss` - Resolution center return styles

### JavaScript:
- `app/javascript/controllers/orders_filter_controller.js` - Dropdown functionality

## Troubleshooting

### Common Issues:

1. **"undefined method return_status" error**:
   - Make sure you ran `rails db:migrate`
   - Check that the migration added return fields to refunds table

2. **Dropdown not appearing**:
   - Check that order has a dispatch with shipped/completed status
   - Verify order doesn't already have a refund

3. **Styles not loading**:
   - Run `rails assets:precompile` if needed
   - Check browser console for CSS errors

4. **Return not appearing in resolution center**:
   - Verify refund was created with `pending_resolution` stage
   - Check that resolution_stage is set to `pending_customer_clarification`

## Quick Test Script

Run the automated test:
```bash
cd /path/to/your/app
ruby test_return_workflow.rb
```

This will create test data and verify the workflow logic.

## Success Criteria

✅ Agents can initiate returns from orders interface  
✅ Return reasons properly route to resolution workflow  
✅ Non-return reasons go to standard refund process  
✅ Resolution center shows return management options  
✅ Return status tracking works through entire lifecycle  
✅ Orders maintain proper status throughout return process  
✅ Turbo streams update UI in real-time  
✅ CSS styling is consistent and responsive