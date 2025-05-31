class SuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier, only: [:show, :edit, :update]

  def index
    @suppliers = Supplier.includes(:activities, :orders, :supplier_products, :products)
                        .order(created_at: :desc)
    
    # Filter by search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @suppliers = @suppliers.where(Supplier.arel_table[:name].matches(search_term))
    end
    
    # Filter by source
    if params[:source].present?
      @suppliers = @suppliers.by_source(params[:source])
    end
    
    # Filter suppliers with orders
    if params[:with_orders] == 'true'
      @suppliers = @suppliers.with_orders
    end
    
    # Track views for loaded suppliers
    @suppliers.limit(50).each(&:track_view)
  end

  def show
    @supplier.track_view
    @recent_activities = @supplier.activities.includes(:user).recent.limit(10)
    @related_orders = @supplier.orders.includes(:dispatch, :refund).recent.limit(10)
    @supplier_products = @supplier.supplier_products.includes(:product).order(:created_at)
    @performance_stats = {
      total_orders: @supplier.orders.count,
      total_products: @supplier.products.count,
      avg_quality_rating: @supplier.average_quality_rating,
      on_time_delivery_rate: @supplier.on_time_delivery_rate,
      preferred_products_count: @supplier.preferred_products.count,
      best_deals_count: @supplier.best_deals.count
    }
  end

  def edit
    @supplier.track_view
  end

  def update
    respond_to do |format|
      if @supplier.update(supplier_params)
        format.html { redirect_to @supplier, notice: 'Supplier was successfully updated.' }
        format.turbo_stream { redirect_to @supplier, notice: 'Supplier was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(:name, :supplier_notes, :total_orders, :source)
  end
end
