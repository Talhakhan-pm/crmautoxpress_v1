// Import and register all your controllers manually
import { application } from "controllers/application"
import HelloController from "./hello_controller"
import OrderFormController from "./order_form_controller"

application.register("hello", HelloController)
application.register("order-form", OrderFormController)

console.log("Controllers registered: hello, order-form")
