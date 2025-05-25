# CRM AutoXpress v1 - Architecture Analysis

## Overview
This document provides a comprehensive analysis of the CRM application's architecture, focusing on Turbo Frames, Turbo Streams, Stimulus controllers, and the order flow dependencies.

## Turbo Frame & Turbo Stream Usage

### Turbo Frames
- **Main Content Frame**: `callbacks/index.html.erb:3` - Main content wrapped in `turbo_frame_tag "main_content"`
- **Navigation Pattern**: Links use `data: { turbo_frame: "main_content" }` for seamless page transitions
- **SPA-like Behavior**: Callback actions target the main content frame for single-page application experience

### Turbo Streams
- **Broadcast Channels**: 
  - `"callbacks"` - Real-time callback updates
  - `"orders"` - Live order management
  - `"dashboard"` - Dashboard metrics updates
- **Real-time Operations**: Automatic updates on create/update/destroy operations
- **Order Broadcasting**: Orders broadcast to `"orders"` channel targeting `"orders-content"` div
- **Dashboard Integration**: Live statistics updates via dashboard metrics broadcast

## Stimulus Controllers

### Primary Controller: order_form_controller.js
**Purpose**: Manages the unified order creation modal with callback conversion capabilities

**Targets**:
- `modal`, `form` - Modal and form elements
- `productPrice`, `taxAmount`, `shippingCost`, `totalAmount` - Pricing calculations
- `customerName`, `customerPhone`, `customerEmail`, `customerAddress` - Customer data
- `productName`, `carYear`, `carMakeModel` - Product and vehicle information

**Values**:
- `callbackId: Number` - ID of callback being converted
- `orderType: String` - "direct" or "conversion" mode

**Key Methods**:
- `checkForCallback()` - Auto-selects callback when converting from callback page
- `setOrderType()` - Toggles between direct sale vs callback conversion mode
- `selectCallback()` - Fetches callback data via AJAX and populates form
- `calculateTotal()` - Real-time price calculations with tax and shipping
- `lookupCustomer()` & `lookupProduct()` - Modal-based data lookup functionality

### Secondary Controller: hello_controller.js
**Purpose**: Simple test controller for Stimulus verification

## Order Flow Dependencies

### Core Model Relationships
```ruby
# Primary Relationships
Order belongs_to :agent_callback (optional)
Order belongs_to :customer (optional)
Order belongs_to :product (optional)
Order belongs_to :agent (User)

# Auto-creation Relationships
AgentCallback → auto-creates → Customer
AgentCallback → auto-creates → Product
Order → auto-creates → Dispatch
Order → auto-creates → AgentCallback (reverse link)
```

### Data Creation Flows

#### 1. Direct Order Flow
```
User creates Order directly
    ↓
Order.create (OrdersController#create)
    ↓
Auto-creates linked AgentCallback (status: 'sale')
    ↓
Auto-creates Dispatch record
    ↓
Broadcasts to "orders" channel
```

#### 2. Callback Conversion Flow
```
AgentCallback exists (from lead capture)
    ↓
User clicks "Convert to Order" 
    ↓
Redirects to /orders/new?callback_id=X
    ↓
Stimulus auto-populates form with callback data
    ↓
Order created with agent_callback_id
    ↓
Callback status updated to 'sale'
    ↓
Broadcasts to both "orders" and "callbacks" channels
```

## Orders-Callbacks-Stimulus Integration

### Connection Points

#### 1. Callback Selection Flow
- **Entry Point**: Callbacks page (`app/views/callbacks/index.html.erb:95-97`)
- **Trigger**: "Convert to Order" button with `href="/orders/new?callback_id=#{callback.id}"`
- **Controller Response**: `OrdersController#new` pre-populates `@order` from callback
- **Stimulus Activation**: `order_form_controller` reads `callbackIdValue` from data attribute

#### 2. Stimulus Data Flow
```javascript
// Auto-detection and mode switching
checkForCallback() → reads callbackIdValue
    ↓
Auto-clicks conversion toggle if callback_id present
    ↓
selectCallback() → fetches via /callbacks/:id.json
    ↓
Populates form fields with customer/vehicle/product data
    ↓
Focus shifts to pricing fields for completion
```

#### 3. Real-time Update Pipeline
- **Order Creation**: Broadcasts to `"orders"` channel via `Order.broadcast_orders_update`
- **Callback Updates**: Status changes broadcast to `"callbacks"` channel
- **Dashboard Metrics**: Live recalculation on callback/order changes
- **Activity Tracking**: All changes logged via `Trackable` concern

### AJAX Endpoints
- `GET /callbacks/:id.json` - Fetches callback data for form population
- `GET /customers.json` - Customer lookup functionality
- `GET /products.json` - Product lookup functionality

### Form States
- **Direct Sale Mode**: Standard order creation form
- **Conversion Mode**: Callback selection panel visible, form pre-populated
- **Auto-population**: Customer, vehicle, and product fields filled from callback data

## Dependencies Summary

### Technical Dependencies
- **Orders depend on**: AgentCallbacks for conversion flow data
- **Stimulus manages**: Bidirectional data flow between callbacks and orders
- **Turbo Streams enable**: Real-time UI updates across multiple users
- **AJAX endpoints provide**: Dynamic data loading for form population

### Business Logic Dependencies
- **Lead Pipeline**: AgentCallback → Customer → Product → Order → Dispatch
- **Status Tracking**: Callback status updates reflect in conversion metrics
- **Activity Logging**: All interactions tracked for audit and analytics
- **Real-time Collaboration**: Multiple agents see live updates during order processing

## Performance Considerations
- **Broadcast Guards**: Seeding operations bypass real-time updates (`unless Rails.env.test?`)
- **Efficient Queries**: Includes and scopes optimize database access
- **Client-side Caching**: Stimulus targets reduce DOM queries
- **Lazy Loading**: AJAX endpoints load data on-demand

## Security Features
- **Authentication**: `before_action :authenticate_user!` on all controllers
- **Authorization**: Orders automatically assigned to current user
- **Data Validation**: Model validations prevent invalid data entry
- **CSRF Protection**: Rails CSRF tokens on all forms