// Import and register all your controllers manually
import { application } from "controllers/application"
import HelloController from "./hello_controller"
import OrderFormController from "./order_form_controller"
import DispatchFormController from "./dispatch_form_controller"
import ModalController from "./modal_controller"
import CallbackFormController from "./callback_form_controller"
import RefundFormController from "./refund_form_controller"
import DispatchCancellationController from "./dispatch_cancellation_controller"
import OrdersFilterController from "./orders_filter_controller"
import OrderResolutionController from "./order_resolution_controller"
import OrderTimelineController from "./order_timeline_controller"
import UnifiedResolutionController from "./unified_resolution_controller"
import DispatchActionsController from "./dispatch_actions_controller"
import DispatchNavigationController from "./dispatch_navigation_controller"
import DispatchFilterController from "./dispatch_filter_controller"
import NavigationController from "./navigation_controller"
import PaginationController from "./pagination_controller"
import NotificationsController from "./notifications_controller"
import CallbackCardController from "./callback_card_controller"
import DashboardFilterController from "./dashboard_filter_controller"

application.register("hello", HelloController)
application.register("order-form", OrderFormController)
application.register("dispatch-form", DispatchFormController)
application.register("modal", ModalController)
application.register("callback-form", CallbackFormController)
application.register("refund-form", RefundFormController)
application.register("dispatch-cancellation", DispatchCancellationController)
application.register("orders-filter", OrdersFilterController)
application.register("order-resolution", OrderResolutionController)
application.register("order-timeline", OrderTimelineController)
application.register("unified-resolution", UnifiedResolutionController)
application.register("dispatch-actions", DispatchActionsController)
application.register("dispatch-navigation", DispatchNavigationController)
application.register("dispatch-filter", DispatchFilterController)
application.register("navigation", NavigationController)
application.register("pagination", PaginationController)
application.register("notifications", NotificationsController)
application.register("callback-card", CallbackCardController)
application.register("dashboard-filter", DashboardFilterController)

console.log("Controllers registered: hello, order-form, dispatch-form, modal, callback-form, refund-form, dispatch-cancellation, orders-filter, order-resolution, order-timeline, unified-resolution, dispatch-actions, dispatch-navigation, dispatch-filter, navigation, pagination, notifications, callback-card, dashboard-filter")
