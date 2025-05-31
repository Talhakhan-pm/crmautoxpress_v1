// Import and register all your controllers manually
import { application } from "controllers/application"
import HelloController from "./hello_controller"
import OrderFormController from "./order_form_controller"
import DispatchFormController from "./dispatch_form_controller"
import ModalController from "./modal_controller"
import RefundFormController from "./refund_form_controller"
import DispatchCancellationController from "./dispatch_cancellation_controller"
import OrdersFilterController from "./orders_filter_controller"
import OrderResolutionController from "./order_resolution_controller"
import OrderTimelineController from "./order_timeline_controller"
import UnifiedResolutionController from "./unified_resolution_controller"
import DispatchActionsController from "./dispatch_actions_controller"
import NavigationController from "./navigation_controller"

application.register("hello", HelloController)
application.register("order-form", OrderFormController)
application.register("dispatch-form", DispatchFormController)
application.register("modal", ModalController)
application.register("refund-form", RefundFormController)
application.register("dispatch-cancellation", DispatchCancellationController)
application.register("orders-filter", OrdersFilterController)
application.register("order-resolution", OrderResolutionController)
application.register("order-timeline", OrderTimelineController)
application.register("unified-resolution", UnifiedResolutionController)
application.register("dispatch-actions", DispatchActionsController)
application.register("navigation", NavigationController)

console.log("Controllers registered: hello, order-form, dispatch-form, modal, refund-form, dispatch-cancellation, orders-filter, order-resolution, order-timeline, unified-resolution, dispatch-actions, navigation")
