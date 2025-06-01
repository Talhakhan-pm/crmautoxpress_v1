# AutoXpress CRM Business Flow Documentation

## **Business Model Overview**
**Automotive Parts E-commerce CRM** - Google Ads Lead Generation → Phone Sales → Supplier Fulfillment → Issue Resolution

---

## **1. LEAD GENERATION & CONVERSION**

### **Lead Sources**
- **Primary Source**: Google Ads (100% of current leads)
- **Tracking**: GCLID and UTM campaigns captured in customer records
- **No other lead sources currently active**

### **Lead Conversion Process**
```
Google Ads Lead → Agent Callback → Follow-up → Sale/No Sale
```

### **Follow-up Methods**
- **90%**: Phone calls
- **10%**: Email or text messaging

### **Current Performance**
- **Conversion Rate**: 20% (callbacks to orders)
- **Challenge**: Conversion rate considered too low
- **Issue**: Callbacks aren't always pushed as aggressively as they should be

### **Team Roles**
- **Agents**: Handle callbacks and convert leads to orders
- **Dispatchers**: Manage fulfillment and issue resolution

---

## **2. ORDER & DISPATCH PROCESS**

### **Business Model**
- **Inventory**: No inventory maintained - all parts sourced from suppliers on-demand
- **Supplier Strategy**: Track orders with various suppliers to build future relationships
- **Success Rate**: 83% successful fulfillment, 17% require resolution workflow

### **Order-to-Dispatch Workflow**
```
Order Created → Auto-Dispatch Creation → Supplier Sourcing → Part Status Check
    ↓
Part Found (83%) → Fulfillment → Completion
    ↓
Part Not Found (17%) → Resolution Workflow
```

### **Critical Success Factor**
- **Dispatch process is the most critical part of the business**
- Real-time tracking through supplier pipeline
- Multiple supplier relationships being developed

---

## **3. ISSUE RESOLUTION WORKFLOW**

### **When Issues Occur**
- **Frequency**: 17% of all orders require resolution
- **Primary Trigger**: "Item not found" during initial supplier sourcing

### **Current Business Process**
1. **Order Placed**: Customer pays for quoted price
2. **Supplier Sourcing**: Dispatcher researches part availability (2-3 days)
3. **Resolution Scenarios**:
   - **Extended Processing**: Part found but delayed shipment (5-7 days)
   - **Price Adjustment**: Part found but higher cost ($100-300 increase typical)
   - **Complete Unavailability**: Part not available in current market

### **Resolution Workflow (Professional Customer Communication)**
```
Supplier Sourcing (2-3 days) → Dispatcher Status Update → Agent Customer Contact:
  ├─ "Sourcing Complete: Extended Processing" → Agent: "Contact Customer: Shipping Delay"
  ├─ "Sourcing Complete: Price Adjustment" → Agent: "Contact Customer: Price Increase $XXX"
  └─ "Sourcing Complete: Unavailable" → Agent: "Process Customer Refund"
```

### **Agent Communication Scripts**
1. **Extended Processing Time**
   - "Part confirmed, processing requires additional 5-7 days"
   - **Customer Response**: Accept delay OR request refund
   
2. **Price Adjustment Required**
   - "Part confirmed at updated market price of $XXX (additional $XXX)"
   - **Customer Response**: Pay difference OR request refund
   
3. **Part Unavailable**
   - "Part currently unavailable in market"
   - **Action**: Process full refund

### **Save the Sale Performance**
- **Shipping Delays**: Customers typically accept delays
- **Price Increases**: Lower customer acceptance rate
- **Goal**: Track "save rate" by agent and scenario type
- **Key Metric**: Percentage of customers who accept delays vs price increases

### **Current Pain Points**
- **Terminology Confusion**: Current "retry supplier" vs "replace" language doesn't match actual business process
- **Screen Redundancy**: Multiple interfaces for single resolution workflow
- **No Save Rate Tracking**: Missing conversion metrics for resolution scenarios
- **Manual Communication**: No automated customer updates during 2-3 day sourcing period

---

## **4. KEY PERFORMANCE METRICS**

### **Primary KPIs**
1. **Orders Placed** - Conversion from callbacks
2. **Orders Dispatched** - Successful fulfillment rate (target: maintain 83%+)
3. **Orders Refunded** - Minimize refund necessity
4. **Orders Returned/Replaced** - Track resolution success
5. **Agent Callback Conversion** - Improve from current 20%

### **SLA Tracking**
- **Current Status**: Available but not yet implemented
- **Potential Use**: Agent performance management
- **Opportunity**: Resolution time optimization

---

## **5. TEAM STRUCTURE & RESPONSIBILITIES**

### **Two-Team Structure**
- **Agents Team**:
  - Handle Google Ads lead callbacks
  - Convert leads to orders
  - Primary sales responsibility
  
- **Dispatchers Team**:
  - Manage supplier relationships
  - Handle order fulfillment
  - Make resolution decisions
  - Process refunds and replacements

### **Decision Authority**
- **Dispatcher Decisions**: Handled by dedicated dispatcher role
- **Agent Decisions**: Limited to sales and initial order creation

---

## **6. TECHNOLOGY INTEGRATION**

### **Real-time Updates**
- Turbo Stream integration for live UI updates
- Activity tracking across all entities
- Comprehensive audit trails

### **Google Ads Integration**
- Lead source tracking
- Campaign attribution
- GCLID preservation throughout customer journey

### **Multi-role Resolution System**
- Agent → Dispatcher → Customer approval workflow
- Progressive resolution stages
- SLA tracking capabilities

---

## **IDENTIFIED OPTIMIZATION OPPORTUNITIES**

### **1. Improve Callback Conversion (Current: 20%)**
- Implement more aggressive follow-up scheduling
- Add conversion rate analytics per agent
- Create automated follow-up reminders
- Develop better callback prioritization

### **2. Consolidate Resolution Interfaces**
- Merge refunds/resolution into unified dispatch management
- Create single screen for all issue resolution decisions
- Implement clear action buttons: "Contact Customer: Shipping Delay" | "Contact Customer: Price Increase" | "Process Refund"
- Add save-the-sale tracking with customer response recording
- Reduce screen jumping and redundancy

### **3. Enhance Dispatch Management**
- Focus on supplier performance tracking
- Implement clear escalation paths for 17% failure rate
- Develop supplier relationship scoring
- Create faster resolution decision workflows

### **4. Implement SLA Performance Management**
- Agent performance tracking
- Resolution time optimization
- Customer satisfaction metrics
- Automated escalation triggers

### **5. Unified Dashboard Development**
- Single view of all key metrics
- Real-time conversion rates
- Dispatch success rates by supplier
- Agent performance comparisons

---

## **WORKFLOW RECOMMENDATIONS**

### **Streamlined Resolution Process**
```
Item Not Found → Dispatcher Sourcing (2-3 days) → Status Update → Agent Action:
  ├─ Extended Processing (5-7 days) → Contact Customer: Accept Delay?
  ├─ Price Adjustment (+$100-300) → Contact Customer: Pay Difference?
  └─ Part Unavailable → Process Refund Immediately
```

### **Save the Sale Workflow**
```
Agent Customer Contact → Customer Decision → Outcome Tracking:
  ├─ Accepts Delay → Order Continues (Save Success)
  ├─ Accepts Price Increase → Collect Payment → Order Continues (Save Success)
  ├─ Declines Delay → Process Refund (Save Failed)
  └─ Declines Price Increase → Process Refund (Save Failed)
```

### **Enhanced Callback Management**
```
Google Ads Lead → Immediate Agent Assignment → Structured Follow-up Schedule:
  ├─ Day 1: Initial call
  ├─ Day 3: Follow-up call
  ├─ Day 7: Email/text
  └─ Day 14: Final attempt
```

### **Integrated Metrics Dashboard**
```
Single Dashboard View:
  ├─ Lead Conversion Rates (by agent)
  ├─ Dispatch Success Rates (by supplier)
  ├─ Resolution Time Tracking
  └─ Revenue and Refund Analytics
```

---

## **BUSINESS IMPACT PRIORITIES**

1. **High Priority**: Dispatch process optimization (most critical for success)
2. **Medium Priority**: Callback conversion improvement (revenue growth)
3. **Medium Priority**: Resolution interface consolidation (operational efficiency)
4. **Low Priority**: SLA implementation (performance management)

---

*Last Updated: 2025-05-28*
*Documentation based on current system analysis and business requirements*