# Resolution Workflow Architecture Documentation

## Overview

This document outlines the comprehensive resolution workflow architecture for handling refunds, returns, replacements, and dispatch management in the AutoXpress CRM system. The architecture provides a unified approach to managing complex customer service scenarios through structured workflows.

## Table of Contents

- [Core Components](#core-components)
- [Data Models](#data-models)
- [Workflow States](#workflow-states)
- [Resolution Process Flow](#resolution-process-flow)
- [Return Management](#return-management)
- [Replacement Order System](#replacement-order-system)
- [Controller Architecture](#controller-architecture)
- [View Architecture](#view-architecture)
- [API Endpoints](#api-endpoints)
- [Business Logic](#business-logic)
- [Integration Points](#integration-points)

## Core Components

### 1. Resolution Center (`/resolution`)
Central dashboard for managing all pending resolutions with real-time updates and comprehensive workflow management.

### 2. Multi-Stage Workflow System
- **Agent Clarification** → Customer contact and detail verification
- **Dispatcher Decision** → Part sourcing and business decisions  
- **Customer Approval** → Customer response to proposed solutions
- **Resolution Completed** → Final outcome and return management

### 3. Return Management System
Complete return lifecycle tracking from authorization through completion with status tracking and condition documentation.

### 4. Replacement Order System
Intelligent replacement order creation with bidirectional linking and inventory management.

## Data Models

### Refund Model (`app/models/refund.rb`)

#### Key Enums
```ruby
enum refund_stage: {
  pending_refund: 0,           # Standard refund processing
  processing_refund: 1,        # Refund in progress
  refunded: 2,                 # Completed refund
  pending_return: 3,           # Customer return required
  returned: 4,                 # Return completed
  urgent_refund: 5,            # Escalated refund
  failed_refund: 6,            # Failed processing
  cancelled_refund: 7,         # Cancelled by user
  pending_resolution: 8,       # Needs resolution workflow
  pending_replacement: 9,      # Replacement order pending
  pending_retry: 10            # Dispatch retry pending
}

enum resolution_stage: {
  pending_customer_clarification: 0,  # Agent needs to contact customer
  pending_dispatch_decision: 1,       # Dispatcher needs to make decision
  pending_customer_approval: 2,       # Customer needs to approve solution
  resolution_completed: 3             # Resolution process complete
}

enum return_status: {
  no_return_required: 0,       # No return needed
  return_requested: 1,         # Return requested by customer
  return_authorized: 2,        # Return approved by dispatcher
  return_label_sent: 3,        # Return label generated and sent
  return_shipped: 4,           # Customer shipped return package
  return_in_transit: 5,        # Return package in transit
  return_delivered: 6,         # Return package delivered
  return_received: 7,          # Return package received and inspected
  return_inspected: 8          # Return inspection completed
}
```

#### Key Methods
- `create_replacement_order` - Creates new replacement order with atomic locking
- `authorize_return_and_refund!` - Authorizes return for full refund
- `authorize_return_and_replacement!` - Authorizes return with replacement
- `mark_return_received!` - Processes return receipt and updates order status
- `has_pending_refund_resolution?` - Determines if resolution workflow is active

### Order Model Integration

#### Status Management
```ruby
def has_pending_refund_resolution?
  return false unless refund.present?
  
  # If resolution is completed and return process is active, show return status
  if refund.resolution_stage == 'resolution_completed' && 
     refund.return_status.present? && 
     !refund.return_status.in?(['no_return_required'])
    return false # Show actual order status (returned, etc.)
  end
  
  # Otherwise check if refund stage is pending resolution
  ['pending_resolution', 'pending_retry', 'pending_replacement'].include?(refund.refund_stage)
end
```

#### Replacement Order Relationships
```ruby
# Bidirectional linking
belongs_to :original_order, class_name: 'Order', optional: true
has_one :replacement_order, class_name: 'Order', foreign_key: 'original_order_id'
```

## Workflow States

### Agent Clarification Stage
**Purpose**: Agent contacts customer to verify details and gather additional information.

**Actions Available**:
- Contact customer via phone/email
- Update corrected customer details
- Add agent notes about findings
- Mark as clarified (moves to dispatcher decision)
- Request additional information
- Escalate to manager

**UI Location**: `_agent_clarification_section.html.erb`

### Dispatcher Decision Stage
**Purpose**: Dispatcher researches part availability and makes business decisions.

**Actions Available**:
- **Part Sourcing Options**:
  - Source with delay (3-7 days)
  - Source at higher cost (price increase)
  - Use compatible alternative (upgrade)
- **Return Management Options**:
  - Authorize return + refund
  - Authorize return + replacement
- **Final Resolution**:
  - Process immediate refund

**UI Location**: `_dispatcher_decision_section.html.erb`

### Customer Approval Stage
**Purpose**: Agent executes dispatcher's instructions and gets customer response.

**Actions Available**:
- Contact customer with specific instructions
- Record customer response
- Customer approved/declined buttons
- Generate return labels
- Track return shipments

**UI Location**: `_customer_approval_section.html.erb`

### Resolution Completed Stage
**Purpose**: Final outcome management and return processing.

**Features**:
- Resolution summary display
- **Return management workflow** for original orders
- Progress tracking for replacements
- Final completion actions

**UI Location**: `_resolution_completed_section.html.erb`

## Resolution Process Flow

### Standard Workflow
```
1. Issue Reported → refund_stage: 'pending_resolution'
                   resolution_stage: 'pending_dispatch_decision'

2. Dispatcher Research → Various sourcing decisions

3. Customer Contact → resolution_stage: 'pending_customer_approval'

4. Resolution Complete → resolution_stage: 'resolution_completed'
                        + Return management begins
```

### Return + Replacement Flow
```
1. Return Authorized → return_status: 'return_authorized'
                       resolution_stage: 'resolution_completed'
                       replacement_order created

2. Generate Label → return_status: 'return_label_sent'

3. Customer Ships → return_status: 'return_shipped'
                    order_status: 'returned'

4. Return Received → return_status: 'return_received'
                     refund_stage: 'processing_refund'

5. Complete Return → refund_stage: 'refunded'
                     order_status: 'cancelled'
```

## Return Management

### Return Lifecycle States

#### 1. Return Authorization
- **Trigger**: Dispatcher authorizes return
- **Status**: `return_authorized`
- **Order Impact**: No change (customer still has item)
- **Next Action**: Generate return label

#### 2. Return Label Generation
- **Trigger**: Agent/Dispatcher generates shipping label
- **Status**: `return_label_sent`
- **Order Impact**: No change
- **Next Action**: Customer ships package

#### 3. Customer Ships Return
- **Trigger**: Customer ships package back
- **Status**: `return_shipped`
- **Order Impact**: Order status → `'returned'`
- **Next Action**: Wait for delivery and inspection

#### 4. Return Received & Inspected
- **Trigger**: Package received and inspected
- **Status**: `return_received`
- **Order Impact**: Order status remains `'returned'`
- **Refund Impact**: `refund_stage` → `'processing_refund'`
- **Next Action**: Complete return processing

#### 5. Return Processing Complete
- **Trigger**: Final completion by dispatcher
- **Status**: Unchanged (return_received)
- **Refund Impact**: `refund_stage` → `'refunded'`
- **Order Impact**: Order status → `'cancelled'` (via sync_order_status)

### Return Management Methods

#### mark_return_received! (Enhanced)
```ruby
def mark_return_received!(condition_notes: nil)
  transaction do
    update!(
      return_status: 'return_received',
      return_received_at: Time.current,
      return_notes: condition_notes || return_notes,
      refund_stage: 'processing_refund'
    )
    
    # Update original order status to 'returned' or 'cancelled'
    if order.respond_to?(:returned!) && !order.returned?
      order.update!(order_status: 'returned')
    elsif !order.cancelled?
      order.update!(order_status: 'cancelled')
    end
    
    # Create activity logs for tracking
    create_activity(...)
  end
end
```

## Replacement Order System

### Creation Process
```ruby
def create_replacement_order
  return nil unless order.present?
  
  # Use database lock to prevent race conditions
  with_lock do
    reload
    return replacement_order if replacement_order_number.present?
    
    # Create new order with all original details
    replacement = Order.create!(
      # ... copy all original order attributes
      source_channel: 'replacement',
      order_status: 'confirmed',
      original_order_id: order.id,
      priority: 'high'
    )
    
    # Link bidirectionally
    update!(replacement_order_number: replacement.order_number)
    order.update!(replacement_order_id: replacement.id)
    
    replacement
  end
end
```

### Race Condition Prevention
- **Database Locking**: Uses `with_lock` for atomic operations
- **Idempotency**: Safe to call multiple times
- **Duplicate Prevention**: Multiple controller endpoints protected

### Linking Strategy
- **Forward Link**: Original order → `replacement_order_id`
- **Backward Link**: Replacement order → `original_order_id`
- **Reference**: Refund → `replacement_order_number`

## Controller Architecture

### Resolution Controller (`app/controllers/resolution_controller.rb`)

#### Core Actions
- `index` - Main dashboard with filtering and metrics
- `update_stage` - Move between resolution stages
- `create_replacement_order` - Central replacement creation
- `complete_refund` - Final refund completion
- `mark_return_received` - Process return receipt

#### Return Management Actions
- `authorize_return_and_refund` - Authorize return for refund
- `authorize_return_and_replacement` - Authorize return for replacement
- `generate_return_label` - Create shipping labels
- `mark_return_shipped` - Mark customer shipment
- `mark_return_received` - Process return receipt

#### Dispatcher Decision Actions
- `accept_delay` - Accept sourcing delay
- `request_price_increase` - Request additional payment
- `send_compatible_alternative` - Approve alternative part
- `dispatcher_refund` - Process immediate refund

### Dispatches Controller Integration

#### Resolved Method Conflicts
**Problem**: Duplicate method definitions causing overwrites
**Solution**: Context-aware method naming

```ruby
# Direct dispatch management
def create_replacement_order
def retry_dispatch
def process_full_refund

# Resolution workflow variants  
def create_replacement_order_from_resolution
def retry_dispatch_from_resolution
def process_full_refund_from_resolution
```

### Refunds Controller Integration
- Basic refund lifecycle management
- Integration with resolution workflow
- SLA analytics and performance metrics

## View Architecture

### Modular Template System

#### Main Templates
- `index.html.erb` - Dashboard with filtering and metrics
- `_resolution_queue_item.html.erb` - Main item template (modular)
- `_simplified_resolution_item.html.erb` - Compact view (legacy)

#### Section Templates (Modular)
- `_agent_clarification_section.html.erb` - Agent workflow
- `_dispatcher_decision_section.html.erb` - Dispatcher workflow  
- `_customer_approval_section.html.erb` - Customer interaction
- `_resolution_completed_section.html.erb` - **Return management**

#### Template Switching Logic
```erb
<% case refund.resolution_stage %>
<% when 'pending_customer_clarification' %>
  <%= render 'agent_clarification_section', refund: refund %>
<% when 'pending_dispatch_decision' %>
  <%= render 'dispatcher_decision_section', refund: refund %>
<% when 'pending_customer_approval' %>
  <%= render 'customer_approval_section', refund: refund %>
<% when 'resolution_completed' %>
  <%= render 'resolution_completed_section', refund: refund %>
<% end %>
```

### Return Management UI

#### Progressive Workflow Display
```erb
<!-- Resolution Completed Section -->
<% if refund.return_status.present? && !refund.return_status.in?(['no_return_required']) %>
  <div class="return-workflow-section">
    <div class="return-header">
      <h7><i class="fas fa-undo"></i> Return Process for Original Order</h7>
      <span class="return-status-badge status-<%= refund.return_status %>">
        <%= refund.return_status.humanize.gsub('_', ' ') %>
      </span>
    </div>
    
    <!-- Progressive action buttons based on current status -->
    <% if refund.return_status == 'return_authorized' %>
      <%= button_to "Generate Return Label", ... %>
    <% elsif refund.return_status == 'return_label_sent' %>
      <%= button_to "Customer Shipped Return", ... %>
    <% elsif refund.return_shipped? || refund.return_in_transit? || refund.return_delivered? %>
      <%= button_to "Return Received & Inspected", ... %>
    <% elsif refund.return_received? %>
      <%= button_to "Complete Return Processing", ... %>
    <% end %>
  </div>
<% end %>
```

## API Endpoints

### Resolution Management
```
GET    /resolution                           # Main dashboard
PATCH  /resolution/:id/stage                 # Update resolution stage
PATCH  /resolution/:id/notes                 # Update notes
POST   /resolution/:id/replacement           # Create replacement order
PATCH  /resolution/:id/complete_refund       # Complete refund processing
```

### Return Management
```
PATCH  /resolution/:id/authorize_return_and_refund        # Authorize return + refund
PATCH  /resolution/:id/authorize_return_and_replacement   # Authorize return + replacement
PATCH  /resolution/:id/generate_return_label              # Generate shipping label
PATCH  /resolution/:id/mark_return_shipped                # Mark customer shipment
PATCH  /resolution/:id/mark_return_received               # Process return receipt
```

### Dispatcher Decisions
```
PATCH  /resolution/:id/accept_delay                       # Accept sourcing delay
PATCH  /resolution/:id/request_price_increase             # Request price increase
PATCH  /resolution/:id/send_compatible_alternative        # Send alternative part
PATCH  /resolution/:id/dispatcher_refund                  # Process immediate refund
```

### Dispatch Integration
```
POST   /dispatches/:id/create_replacement_order           # Direct dispatch replacement
POST   /dispatches/:id/create_replacement_order_from_resolution # Resolution workflow
PATCH  /dispatches/:id/retry_dispatch_from_resolution     # Resolution retry
PATCH  /dispatches/:id/process_full_refund_from_resolution # Resolution refund
```

## Business Logic

### Resolution Stage Transitions

#### Agent → Dispatcher
- Agent marks customer contacted
- Corrected details and notes captured
- Auto-transition to dispatcher decision stage

#### Dispatcher → Customer Approval
- Dispatcher makes sourcing decision
- Agent instructions generated automatically
- Customer approval stage activated

#### Customer Approval → Completed
- Agent records customer response
- Resolution marked as completed
- Return workflow begins (if applicable)

### Return Process Logic

#### Return Authorization Triggers
1. **Return + Refund**: Customer gets full refund after return
2. **Return + Replacement**: Customer gets new item after return
3. **Quality Issues**: Defective product returns
4. **Wrong Product**: Incorrect item returns

#### Status Synchronization
- **Return Shipped**: Order status → `'returned'`
- **Return Received**: Refund stage → `'processing_refund'`
- **Return Completed**: Order status → `'cancelled'`

### Replacement Order Logic

#### Creation Conditions
- Original order must exist
- No existing replacement order
- Authorized through resolution workflow
- Atomic creation with database locking

#### Inheritance Rules
- Copy all customer information
- Copy all product details
- Copy pricing and amounts
- Set priority to `'high'`
- Set source to `'replacement'`
- Set status to `'confirmed'`

## Integration Points

### Order Management Integration
- **Status Synchronization**: Order status updates based on resolution progress
- **Display Logic**: `has_pending_refund_resolution?` controls UI display
- **Activity Tracking**: All changes logged to order timeline

### Dispatch System Integration
- **Cancellation Logic**: Dispatch cancelled when return authorized
- **Retry Workflow**: Dispatch reset for alternative sourcing
- **Dual Context**: Separate methods for direct vs resolution workflows

### Customer Communication
- **Contact Information**: Automatic population from orders
- **Email Integration**: Direct mailto links for customer contact
- **Phone Integration**: Direct tel links for customer calls

### Activity Tracking
- **Resolution Activities**: All stage changes logged
- **Return Activities**: Full return lifecycle tracked
- **Order Activities**: Cross-model activity aggregation

### Real-Time Updates
- **Turbo Streams**: Live dashboard updates
- **Broadcast Integration**: Multi-view synchronization
- **State Management**: Consistent UI state across sessions

## Performance Considerations

### Database Optimizations
- **Includes**: Eager loading for related models
- **Indexing**: Optimized queries for resolution filtering
- **Atomic Operations**: Database locking for critical operations

### Caching Strategy
- **Instance Variables**: Smart caching for replacement order lookups
- **Scope Optimization**: Efficient filtering and searching
- **Broadcast Efficiency**: Targeted updates only

### Scalability Features
- **Pagination**: Limited result sets for large datasets
- **Filtering**: Multiple filter options for focused views
- **Async Operations**: Non-blocking UI updates

## Testing Strategy

### Model Testing
- **State Transitions**: Verify proper workflow progression
- **Business Logic**: Test replacement creation and return processing
- **Edge Cases**: Handle race conditions and invalid states

### Controller Testing
- **Action Coverage**: Test all resolution workflow actions
- **Integration**: Verify cross-controller method interactions
- **Error Handling**: Test failure scenarios and edge cases

### View Testing
- **Template Rendering**: Verify correct section display
- **State Display**: Test UI state for all workflow stages
- **User Interactions**: Test button availability and progression

## Future Enhancements

### Planned Features
- **Customer Portal**: Self-service return status checking
- **Advanced Analytics**: Resolution performance metrics
- **Automated Decisions**: AI-powered dispatcher recommendations
- **Integration APIs**: External shipping and inventory systems

### Scalability Improvements
- **Background Jobs**: Async processing for heavy operations
- **Event Sourcing**: Comprehensive audit trail
- **Microservices**: Separate resolution service
- **Advanced Caching**: Redis-based state management

---

*This architecture document reflects the current state of the resolution workflow system as of the latest implementation. The system provides comprehensive management of complex customer service scenarios through structured workflows, atomic operations, and intelligent UI design.*