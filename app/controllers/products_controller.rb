class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update]

  def index
    @products = Product.includes(:activities, supplier_products: [:supplier])
                      .order(created_at: :desc)
    
    # Filter by search
    if params[:search].present?
      @products = @products.search(params[:search])
    end
    
    # Filter by category
    if params[:category].present?
      @products = @products.by_category(params[:category])
    end
    
    # Filter by status
    if params[:status].present?
      @products = @products.where(status: params[:status])
    end
    
    # Filter by source
    if params[:source].present?
      @products = @products.by_source(params[:source])
    end
    
    # Track views for loaded products
    @products.limit(50).each(&:track_view)
  end

  def show
    @product.track_view
    @recent_activities = @product.activities.includes(:user).recent.limit(10)
    @related_callbacks = AgentCallback.where(AgentCallback.arel_table[:product].matches("%#{@product.name}%")).limit(10)
    @product_suppliers = @product.supplier_products.includes(:supplier).order(:created_at)
  end

  def edit
    @product.track_view
  end

  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.turbo_stream { redirect_to @product, notice: 'Product was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :part_number, :oem_part_number, :description, 
                                   :category, :vendor_name, :vendor_cost, :selling_price, 
                                   :lead_time_days, :vehicle_compatibility, :status)
  end
end