// Callbacks page functionality

function openModal() {
    document.getElementById('addCallbackModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeModal() {
    document.getElementById('addCallbackModal').classList.remove('active');
    document.body.style.overflow = 'auto';
}

// Status filter functionality
function applyStatusFilter(status) {
    const rows = document.querySelectorAll('#callbacks tr[data-status]');
    let visibleCount = 0;
    
    rows.forEach(row => {
        if (status === 'all' || row.dataset.status === status) {
            row.style.display = '';
            visibleCount++;
        } else {
            row.style.display = 'none';
        }
    });
    
    // Update pagination info
    const totalRows = rows.length;
    const paginationInfo = document.querySelector('.pagination-info');
    if (paginationInfo) {
        paginationInfo.textContent = `Showing ${visibleCount} of ${totalRows} results`;
    }
}

// Initialize callbacks functionality when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Close modal when clicking outside
    const modal = document.getElementById('addCallbackModal');
    if (modal) {
        modal.addEventListener('click', function(e) {
            if (e.target === this) {
                closeModal();
            }
        });
    }

    // Handle form submission
    const callbackForm = document.getElementById('callback-form');
    if (callbackForm) {
        callbackForm.addEventListener('submit', function(e) {
            // Form will submit normally, but we can add validation here if needed
            console.log('Submitting callback form...');
        });
    }

    // Filter functionality
    document.querySelectorAll('.filter-btn[data-status]').forEach(btn => {
        btn.addEventListener('click', function() {
            // Remove active class from all filter buttons in the same group
            const group = this.closest('.filter-group');
            if (group) {
                group.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                this.classList.add('active');
            }
            
            // Apply status filter
            const status = this.dataset.status;
            applyStatusFilter(status);
        });
    });

    // Search functionality
    const searchInput = document.querySelector('.search-box input');
    if (searchInput) {
        searchInput.addEventListener('input', function(e) {
            const searchTerm = e.target.value.toLowerCase();
            const rows = document.querySelectorAll('#callbacks tr[data-status]');
            let visibleCount = 0;
            
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                const shouldShow = text.includes(searchTerm);
                const statusFilter = document.querySelector('.filter-btn.active');
                const activeStatus = statusFilter ? statusFilter.dataset.status : 'all';
                const matchesStatus = activeStatus === 'all' || row.dataset.status === activeStatus;
                
                if (shouldShow && matchesStatus) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });
            
            // Update pagination info
            const totalRows = rows.length;
            const paginationInfo = document.querySelector('.pagination-info');
            if (paginationInfo) {
                paginationInfo.textContent = `Showing ${visibleCount} of ${totalRows} results`;
            }
        });
    }
    
    // Initialize with all items showing
    applyStatusFilter('all');
});

// Handle new items added via turbo streams (live broadcasting)
document.addEventListener('turbo:before-stream-render', function(event) {
    setTimeout(() => {
        const activeFilter = document.querySelector('.filter-btn.active');
        if (activeFilter) {
            applyStatusFilter(activeFilter.dataset.status);
        }
    }, 10);
});

// Make functions globally available
window.openModal = openModal;
window.closeModal = closeModal;
window.applyStatusFilter = applyStatusFilter;