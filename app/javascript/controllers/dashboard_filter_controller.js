import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["metrics", "statusChart", "trendChart", "filterBtn", "chartBtn"]
  static values = { 
    period: String,
    chartType: String,
    statusData: Object,
    trendData: Array
  }

  connect() {
    this.currentPeriod = "today"
    this.currentChartType = "donut"
    this.statusChart = null
    this.trendChart = null
    
    // Initialize charts after a brief delay to ensure canvas elements are ready
    setTimeout(() => {
      this.initializeCharts()
    }, 100)
  }

  disconnect() {
    if (this.statusChart) {
      this.statusChart.destroy()
    }
    if (this.trendChart) {
      this.trendChart.destroy()
    }
  }

  // Filter button click handler
  filterPeriod(event) {
    const period = event.currentTarget.dataset.period
    if (period === this.currentPeriod) return

    this.currentPeriod = period
    this.updateActiveFilterButton(event.currentTarget)
    this.fetchDashboardData(period)
  }

  // Chart type button click handler  
  switchChart(event) {
    const chartType = event.currentTarget.dataset.chart
    if (chartType === this.currentChartType) return

    this.currentChartType = chartType
    this.updateActiveChartButton(event.currentTarget)
    this.updateStatusChart(chartType)
  }

  // Update active state for filter buttons
  updateActiveFilterButton(activeButton) {
    this.filterBtnTargets.forEach(btn => {
      btn.classList.remove('active')
    })
    activeButton.classList.add('active')
  }

  // Update active state for chart buttons
  updateActiveChartButton(activeButton) {
    this.chartBtnTargets.forEach(btn => {
      btn.classList.remove('active')
    })
    activeButton.classList.add('active')
  }

  // Fetch new dashboard data via AJAX
  async fetchDashboardData(period) {
    try {
      // Show loading state
      this.showLoadingState()

      const response = await fetch(`/dashboard?period=${period}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error('Network response was not ok')
      }

      const data = await response.json()
      this.updateDashboard(data)
      
    } catch (error) {
      console.error('Error fetching dashboard data:', error)
      this.showErrorState()
    } finally {
      this.hideLoadingState()
    }
  }

  // Initialize Chart.js charts
  initializeCharts() {
    this.initializeStatusChart()
    this.initializeTrendChart()
  }

  initializeStatusChart() {
    const canvas = this.statusChartTarget
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    const statusData = this.statusDataValue || {}

    this.statusChart = new Chart(ctx, {
      type: this.currentChartType === 'donut' ? 'doughnut' : 'bar',
      data: {
        labels: Object.keys(statusData),
        datasets: [{
          data: Object.values(statusData),
          backgroundColor: [
            '#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'
          ],
          borderWidth: 0
        }]
      },
      options: this.getChartOptions(this.currentChartType)
    })
  }

  initializeTrendChart() {
    const canvas = this.trendChartTarget
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    const trendData = this.trendDataValue || []

    this.trendChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: trendData.map(d => d.date),
        datasets: [{
          label: 'Leads',
          data: trendData.map(d => d.leads),
          borderColor: '#6366f1',
          backgroundColor: 'rgba(99, 102, 241, 0.1)',
          tension: 0.4,
          fill: true
        }, {
          label: 'Sales',
          data: trendData.map(d => d.sales),
          borderColor: '#10b981',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          tension: 0.4,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { intersect: false },
        plugins: {
          legend: { display: true }
        },
        scales: {
          y: { beginAtZero: true }
        }
      }
    })
  }

  // Update status chart type
  updateStatusChart(chartType) {
    if (!this.statusChart) return

    const newType = chartType === 'donut' ? 'doughnut' : 'bar'
    
    this.statusChart.destroy()
    
    const ctx = this.statusChartTarget.getContext('2d')
    this.statusChart = new Chart(ctx, {
      type: newType,
      data: this.statusChart.data,
      options: this.getChartOptions(chartType)
    })
  }

  // Get chart options based on type
  getChartOptions(chartType) {
    const baseOptions = {
      responsive: true,
      maintainAspectRatio: false
    }

    if (chartType === 'donut') {
      return {
        ...baseOptions,
        plugins: {
          legend: {
            position: 'bottom',
            labels: { usePointStyle: true }
          }
        }
      }
    } else {
      return {
        ...baseOptions,
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: { beginAtZero: true }
        }
      }
    }
  }

  // Update dashboard with new data
  updateDashboard(data) {
    // Update metrics
    if (this.hasMetricsTarget && data.stats) {
      this.updateMetrics(data.stats)
    }

    // Update charts
    if (data.chart_data) {
      this.updateCharts(data.chart_data)
    }
  }

  // Update metrics cards
  updateMetrics(stats) {
    const metricsContainer = this.metricsTarget
    
    // Find and update each metric value
    Object.keys(stats).forEach(key => {
      const metricElement = metricsContainer.querySelector(`[data-metric="${key}"]`)
      if (metricElement) {
        const valueElement = metricElement.querySelector('.metric-value')
        if (valueElement) {
          valueElement.textContent = this.formatMetricValue(key, stats[key])
        }
      }
    })
  }

  // Update chart data
  updateCharts(chartData) {
    // Update status chart data
    if (this.statusChart && chartData.lead_status_distribution) {
      this.statusChart.data.labels = Object.keys(chartData.lead_status_distribution)
      this.statusChart.data.datasets[0].data = Object.values(chartData.lead_status_distribution)
      this.statusChart.update('active')
    }

    // Update trend chart data
    if (this.trendChart && chartData.daily_leads_trend) {
      const trendData = chartData.daily_leads_trend
      this.trendChart.data.labels = trendData.map(d => d.date)
      this.trendChart.data.datasets[0].data = trendData.map(d => d.leads)
      this.trendChart.data.datasets[1].data = trendData.map(d => d.sales)
      this.trendChart.update('active')
    }
  }

  // Format metric values for display
  formatMetricValue(key, value) {
    switch (key) {
      case 'conversion_rate':
        return `${value}%`
      case 'avg_lead_value':
        return `$${value.toLocaleString()}`
      default:
        return value.toLocaleString()
    }
  }

  // Loading state management
  showLoadingState() {
    this.element.classList.add('dashboard-loading')
    
    // Add loading overlay if it doesn't exist
    if (!this.element.querySelector('.loading-overlay')) {
      const overlay = document.createElement('div')
      overlay.className = 'loading-overlay'
      overlay.innerHTML = `
        <div class="loading-spinner">
          <i class="fas fa-spinner fa-spin"></i>
          <span>Updating dashboard...</span>
        </div>
      `
      this.element.appendChild(overlay)
    }
  }

  hideLoadingState() {
    this.element.classList.remove('dashboard-loading')
    const overlay = this.element.querySelector('.loading-overlay')
    if (overlay) {
      overlay.remove()
    }
  }

  showErrorState() {
    // Show error message or revert to previous state
    console.log('Dashboard update failed, please try again')
  }
}