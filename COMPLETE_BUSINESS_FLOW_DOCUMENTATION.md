# AutoXpress CRM - Complete Business Flow Documentation

## System Overview

AutoXpress is a comprehensive CRM system for auto parts sales with integrated order management, dispatch tracking, and refund/return processing. The system handles the complete customer journey from initial contact through order fulfillment and post-sale support.

## Core Data Models & Relationships

### Entity Relationships
```
Customer (1) ←→ (N) AgentCallback
Customer (1) ←→ (N) Order
User/Agent (1) ←→ (N) AgentCallback
User/Agent (1) ←→ (N) Order (as agent)
User/Agent (1) ←→ (N) Order (as processing_agent)
User/Agent (1) ←→ (N) Dispatch (as processing_agent)
Order (1) ←→ (1) Dispatch
Order (1) ←→ (1) Refund
Order (N) ←→ (1) Supplier
Product (1) ←→ (N) Order
AgentCallback (1) ←→ (N) Order (conversion)
Order (1) ←→ (1) Order (replacement orders)
```

### Key Status Flows

#### AgentCallback Statuses
- `pending` → `not_interested` | `already_purchased` | `sale` | `payment_link` | `follow_up`

#### Order Statuses  
- `pending` → `confirmed` → `processing` → `shipped` → `delivered`
- `cancelled` | `returned` | `refunded` (terminal states)

#### Dispatch Statuses
- `pending` → `assigned` → `processing` → `shipped` → `completed`
- `cancelled` (can happen from any state)

#### Refund Stages
- `pending_refund` → `processing_refund` → `refunded`
- `pending_return` → `returned`
- `pending_resolution` → `pending_retry` | `pending_replacement`
- `urgent_refund` | `failed_refund` | `cancelled_refund`

#### Resolution Stages (for complex refunds)
- `pending_customer_clarification` → `pending_dispatch_decision` → `pending_customer_approval` → `resolution_completed`

## 1. CALLBACK TO ORDER CONVERSION PROCESS

### Initial Contact - AgentCallback Creation
**Location**: `callbacks_controller.rb:create` (line 31-61)

1. **Agent receives customer call**
   - Creates AgentCallback record with customer details
   - Auto-creates Customer record if phone number is new (`agent_callback.rb:73-99`)
   - Auto-extracts Product record from callback text (`agent_callback.rb:101-139`)
   - Stores Google Ads data if provided (UTM tracking)

2. **Callback Processing**
   - Status: `pending` (default)
   - Agent can update status to: `not_interested`, `already_purchased`, `sale`, `payment_link`, `follow_up`
   - Broadcasts real-time updates to dashboard metrics

### Order Conversion Process
**Location**: `orders_controller.rb:new` (line 42-55), `order_form_controller.js`

1. **Agent initiates order creation**
   - Two paths: 
     - Direct order creation (new customer)
     - Callback conversion (existing callback)

2. **Callback Conversion Flow**
   - Order form pre-populated from callback data (`orders_controller.rb:52-54`)
   - JavaScript auto-selects callback and populates fields (`order_form_controller.js:61-89`)
   - Agent adds pricing and finalizes order

3. **Order Creation Process** (`orders_controller.rb:create` line 57-95)
   - Generates unique order number (`order.rb:340-344`)
   - Auto-creates Customer if needed (`order.rb:388-412`)
   - Auto-creates Product if needed (`order.rb:414-449`)
   - Creates linked Dispatch record (`order.rb:367-386`)
   - Updates original callback status to 'sale' (`orders_controller.rb:74-77`)
   - Auto-creates reverse AgentCallback for tracking (`order.rb:462-491`)

## 2. ORDER STATUS AND DISPATCH WORKFLOW

### Order Lifecycle
**Primary Location**: `order.rb`, `dispatch.rb`

#### Order Creation → Dispatch Assignment
1. **Order Created** (`pending` status)
   - Auto-creates Dispatch record with `pending` status
   - Payment status set to `paid` by default
   - Commission calculated if supplier cost present (`order.rb:353-365`)

2. **Order Confirmation** (`confirmed` status)
   - Agent reviews and confirms order details
   - Dispatch status moves to `assigned`
   - Order ready for processing

#### Dispatch Processing Flow
**Location**: `dispatches_controller.rb`, `dispatch_form_controller.js`

1. **Dispatch Assignment** (`assigned` status)
   - Processing agent assigned
   - Supplier selection begins
   - Real-time profit calculation (`dispatch_form_controller.js:150-189`)

2. **Supplier Sourcing** (`processing` status)
   - Agent searches/selects supplier
   - Supplier autocomplete with create-new functionality (`dispatch_form_controller.js:600-769`)
   - Supplier cost, shipping, tax entered
   - Profit margins calculated in real-time
   - Commission (3% of profit) auto-calculated

3. **Order Fulfillment** (`shipped` status)
   - Tracking number assigned
   - Shipping carrier selected
   - Customer notification sent
   - Timeline updated with delivery estimates

4. **Completion** (`completed` status)
   - Delivery confirmed
   - Order marked as delivered
   - Customer satisfaction tracked

### Dispatch Cancellation & Resolution
**Location**: `dispatch_cancellation_controller.js`, `dispatches_controller.rb:cancel_with_reason`

When dispatcher cancels a dispatch:
1. **Cancellation Modal** triggers (`dispatch_cancellation_controller.js:18-52`)
2. **Reason Selection**:
   - `item_not_found` → Price increase scenario
   - `supplier_issue` → Refund scenario
   - `shipping_delay` → Customer contact scenario
   - Custom reasons supported
3. **Auto-Refund Creation** (`dispatches_controller.rb:279-326`)
   - Creates refund with `pending_resolution` stage
   - Multiple resolution options available

## 3. RETURN/REFUND RESOLUTION PROCESS

### Refund Creation Triggers
**Location**: `refunds_controller.rb`, `dispatch.rb:handle_dispatch_cancellation`

1. **Manual Refund Request**
   - Customer requests return/refund
   - Agent creates refund with reason selection
   - Stage determined by reason type (`refund.rb:722-734`)

2. **Auto-Refund from Dispatch Cancellation**
   - Dispatch cancelled → Auto-creates refund
   - Refund stage: `pending_resolution`
   - Resolution workflow triggered

### Resolution Workflow Stages
**Location**: `resolution_controller.rb`, `unified_resolution_controller.js`

#### Stage 1: Customer Clarification (`pending_customer_clarification`)
**What Agents See**: Resolution queue with customer contact options
**What Dispatchers See**: Pending items waiting for agent action

**Agent Actions**:
- Contact customer about issue details
- Gather additional information
- Update customer response notes
- Move to dispatcher decision stage

#### Stage 2: Dispatcher Decision (`pending_dispatch_decision`)
**What Agents See**: Items awaiting dispatcher review
**What Dispatchers See**: Resolution queue requiring sourcing decisions

**Dispatcher Actions** (`resolution_controller.rb:302-384`):
- **Accept Delay**: Part available with shipping delay
- **Request Price Increase**: Part costs more than customer paid
- **Send Compatible Alternative**: Found substitute part
- **Issue Refund**: Part not economically viable to source

#### Stage 3: Customer Approval (`pending_customer_approval`)
**What Agents See**: Items requiring customer contact with dispatcher instructions
**What Dispatchers See**: Items waiting for customer response

**Agent Actions**:
- Contact customer with dispatcher's decision
- Record customer approval/decline
- Execute approved resolution

#### Stage 4: Resolution Complete (`resolution_completed`)
**What Agents See**: Completed resolutions
**What Dispatchers See**: Closed items

### Return Management Process
**Location**: `dispatch_actions_controller.js`, `resolution_controller.rb:567-699`

#### Return Authorization Flow
1. **Return Request** (`return_requested` status)
   - Customer initiates return
   - Refund created with return status

2. **Return Authorization** (`return_authorized` status)
   - Dispatcher authorizes return
   - Two options:
     - Return + Refund (`authorize_return_and_refund`)
     - Return + Replacement (`authorize_return_and_replacement`)

3. **Return Label Generation** (`return_label_sent` status)
   - System generates return shipping label
   - Customer receives return instructions
   - 14-day return deadline set

4. **Return Shipment** (`return_shipped` → `return_received` status)
   - Customer ships return package
   - Tracking number recorded
   - Return received and inspected
   - Condition notes recorded

5. **Refund Processing**
   - Return inspection complete
   - Refund stage moves to `processing_refund` → `refunded`
   - Order status updated to `returned` or `cancelled`

### Replacement Order Process
**Location**: `refund.rb:846-897`, `dispatch_actions_controller.js:137-173`

1. **Replacement Creation**
   - New Order created with `source_channel: 'replacement'`
   - Links to original order (`original_order_id`)
   - High priority assigned
   - Same customer/product details

2. **Replacement Processing**
   - Goes through normal dispatch workflow
   - Tracked separately from original order
   - Original order marked as replaced

## 4. USER ROLES & RESPONSIBILITIES

### Agents
**Primary Functions**:
- Handle incoming customer calls (Callbacks)
- Convert callbacks to orders
- Contact customers for resolution clarification
- Record customer responses and decisions
- Process final resolution actions

**Key Views**:
- Callbacks dashboard
- Order creation forms
- Resolution queue (pending customer clarification)
- Customer communication tools

### Dispatchers
**Primary Functions**:
- Process confirmed orders
- Source parts from suppliers
- Make dispatch decisions
- Handle resolution escalations
- Manage returns and replacements

**Key Views**:
- Dispatch management dashboard
- Supplier sourcing tools
- Resolution queue (pending dispatch decision)
- Return management interface

### Processing Agents
**Primary Functions**:
- Execute dispatch operations
- Update order statuses
- Manage shipping and tracking
- Handle post-sale support

**Key Views**:
- Dispatch processing interface
- Order timeline management
- Shipment tracking tools

## 5. SYSTEM INTEGRATIONS & AUTOMATION

### Real-time Updates
**Technology**: Turbo Streams with ActionCable
**Implementation**: 
- Order updates broadcast to all relevant views
- Dashboard metrics update in real-time
- Resolution queue updates automatically
- Status changes propagate across related records

### Auto-generated Records
1. **Customer Auto-creation**: From callbacks and orders
2. **Product Auto-extraction**: From callback descriptions
3. **Supplier Auto-creation**: From dispatch forms
4. **Activity Tracking**: All actions logged with user attribution
5. **Reverse Callbacks**: Created when orders placed directly

### Commission & Profit Calculation
- **Real-time calculation**: As supplier costs are entered
- **Commission rate**: 3% of profit (customer total - supplier total)
- **Profit margins**: Displayed as percentage and dollar amount
- **Cost tracking**: Product cost vs supplier cost comparison

## 6. CRITICAL BUSINESS FLOWS

### High-Priority Resolution Path
```
Dispatch Cancelled → Auto-Refund (pending_resolution) → Agent Contact → Dispatcher Decision → Customer Approval → Resolution Complete
```

### Return-to-Replacement Path
```
Customer Return Request → Return Authorization → Return Label → Customer Ships → Return Received → Replacement Order Created → New Dispatch Process
```

### Callback-to-Sale Path
```
Customer Call → Callback Created → Agent Conversion → Order Created → Dispatch Assigned → Supplier Sourced → Shipped → Delivered
```

## 7. PERFORMANCE & SLA TRACKING

### Refund SLA Management
**Location**: `refund.rb:388-446`

- **SLA Targets**: 
  - Pending refund: 3 days
  - Processing refund: 7 days
  - Pending return: 14 days
  - Pending resolution: 2 days

- **Auto-escalation**: Overdue items automatically marked urgent
- **Performance scoring**: Based on resolution time vs SLA targets
- **Agent metrics**: Individual performance tracking

### Resolution Analytics
**Location**: `resolution_controller.rb:411-493`

- **Queue metrics**: Items by stage and priority
- **Completion rates**: Percentage of resolved items
- **Average resolution time**: Days from creation to completion
- **Agent performance**: Individual resolution metrics

## 8. ERROR HANDLING & EDGE CASES

### Duplicate Prevention
- **1:1 Relationships**: Order-Dispatch, Order-Refund enforced
- **Unique constraints**: Order numbers, refund numbers, customer phone numbers
- **Callback linking**: Prevents duplicate callback creation from orders

### Status Validation
- **Valid transitions**: Enforced at model level
- **Concurrent updates**: Database locks prevent race conditions
- **Rollback scenarios**: Failed operations roll back cleanly

### Data Integrity
- **Cascading updates**: Order status changes propagate to dispatch
- **Activity logging**: All changes tracked with user attribution
- **Soft validation**: User-friendly error messages

This documentation provides a complete overview of the AutoXpress CRM system's business flows, from initial customer contact through order fulfillment and post-sale resolution processes.