// Import and register all your controllers manually
import { application } from "controllers/application"
import HelloController from "./hello_controller"
import OrderFormController from "./order_form_controller"
import DispatchFormController from "./dispatch_form_controller"
import ModalController from "./modal_controller"
import RefundFormController from "./refund_form_controller"
import DispatchCancellationController from "./dispatch_cancellation_controller"
import OrdersFilterController from "./orders_filter_controller"

application.register("hello", HelloController)
application.register("order-form", OrderFormController)
application.register("dispatch-form", DispatchFormController)
application.register("modal", ModalController)
application.register("refund-form", RefundFormController)
application.register("dispatch-cancellation", DispatchCancellationController)
application.register("orders-filter", OrdersFilterController)

console.log("Controllers registered: hello, order-form, dispatch-form, modal, refund-form, dispatch-cancellation, orders-filter")
