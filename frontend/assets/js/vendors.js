// API Configuration
const API_BASE_URL = 'https://1o8pl970wc.execute-api.eu-west-1.amazonaws.com/dev';
const LANDING_TECH_CATEGORIES = [
    'Performance Tracking',
    'Video Analysis',
    'Analytics & AI',
    'Recovery & Medical',
    'Fan Engagement',
    'Facilities & Infrastructure',
    'Business Operations',
    'Scouting & Recruitment',
    'Content & Broadcasting'
];

// State
let allVendors = [];
let filteredVendors = [];

// DOM Elements
const searchInput = document.getElementById('search-input');
const categoryFilter = document.getElementById('category-filter');
const vendorsList = document.getElementById('vendors-list');
const resultsCount = document.getElementById('results-count');
const loading = document.getElementById('loading');
const error = document.getElementById('error');
const noResults = document.getElementById('no-results');
const vendorsHeadlineCount = document.getElementById('vendors-headline-count');
const vendorsHeadlineCategoryCount = document.getElementById('vendors-headline-category-count');

// Fetch vendors from API
async function loadVendors() {
    try {
        loading.classList.remove('hidden');
        error.classList.add('hidden');
        
        const response = await fetch(`${API_BASE_URL}/vendors`);
        if (!response.ok) throw new Error('Failed to fetch vendors');
        
        const data = await response.json();
        // API may return {count, vendors: [...]} or a direct vendors array
        allVendors = data.vendors || data; // Handle both formats
        filteredVendors = [...allVendors];

        updateHeadlineMetrics();
        
        loading.classList.add('hidden');
        displayVendors();
        
    } catch (err) {
        console.error('Error loading vendors:', err);
        loading.classList.add('hidden');
        error.classList.remove('hidden');
    }
}

function updateHeadlineMetrics() {
    if (vendorsHeadlineCount) {
        vendorsHeadlineCount.textContent = allVendors.length;
    }

    if (vendorsHeadlineCategoryCount) {
        vendorsHeadlineCategoryCount.textContent = LANDING_TECH_CATEGORIES.length;
    }
}

// Display vendors
function displayVendors() {
    if (filteredVendors.length === 0) {
        vendorsList.classList.add('hidden');
        noResults.classList.remove('hidden');
        resultsCount.textContent = '0';
        return;
    }
    
    vendorsList.classList.remove('hidden');
    noResults.classList.add('hidden');
    
    vendorsList.innerHTML = filteredVendors.map(vendor => createVendorCard(vendor)).join('');
    resultsCount.textContent = filteredVendors.length;
}

// Category emoji mapping
const categoryEmojis = {
    // Standard display format
    'Performance Tracking': '⚡',
    'Video Analysis': '🎥',
    'Analytics & AI': '🧠',
    'Recovery & Medical': '💚',
    'Fan Engagement': '📱',
    'Facilities & Infrastructure': '🏟️',
    'Business Operations': '📊',
    'Scouting & Recruitment': '🔍',
    'Content & Broadcasting': '📹',
    // Database formats (with hyphens)
    'performance-tracking': '⚡',
    'video-analysis': '🎥',
    'data-analytics': '🧠',
    'analytics-ai': '🧠',
    'recovery-and-medical': '💚',
    'fan-engagement': '📱',
    'facilities-and-infrastructure': '🏟️',
    'business-operations': '📊',
    'scouting-and-recruitment': '🔍',
    'content-and-broadcasting': '📹',
    // API variations (alternate forms)
    'Data Analytics': '🧠',
    'Recovery': '💚',
    'Facility': '🏟️',
    'Scouting': '🔍',
    'Content': '📹'
};

// Normalize category names to standard form
function normalizeCategory(category) {
    if (!category) return category;
    
    // Remove CATEGORY# prefix if present and lowercase for comparison
    const cleanCategory = category.replace(/^CATEGORY#/, '').toLowerCase();
    
    // Map all variations (database format, API format, display format) to standard names
    const categoryMap = {
        // Database formats (with hyphens)
        'data-analytics': 'Analytics & AI',
        'content-and-broadcasting': 'Content & Broadcasting',
        'recovery-and-medical': 'Recovery & Medical',
        'facilities-and-infrastructure': 'Facilities & Infrastructure',
        'scouting-and-recruitment': 'Scouting & Recruitment',
        'performance-tracking': 'Performance Tracking',
        'video-analysis': 'Video Analysis',
        'fan-engagement': 'Fan Engagement',
        'business-operations': 'Business Operations',
        // API variations (no hyphens)
        'data analytics': 'Analytics & AI',
        'content and broadcasting': 'Content & Broadcasting',
        'recovery and medical': 'Recovery & Medical',
        'facilities and infrastructure': 'Facilities & Infrastructure',
        'scouting and recruitment': 'Scouting & Recruitment',
        'performance tracking': 'Performance Tracking',
        'video analysis': 'Video Analysis',
        'fan engagement': 'Fan Engagement',
        'business operations': 'Business Operations',
        // Additional aliases
        'Data Analytics': 'Analytics & AI',
        'Recovery': 'Recovery & Medical',
        'Facility': 'Facilities & Infrastructure',
        'Scouting': 'Scouting & Recruitment',
        'Content': 'Content & Broadcasting'
    };
    
    return categoryMap[cleanCategory] || category;
}

function getVendorCategories(vendor) {
    // API currently returns Categories[]; keep PrimaryCategory as fallback for compatibility.
    const rawCategories = Array.isArray(vendor.Categories) && vendor.Categories.length > 0
        ? vendor.Categories
        : (vendor.PrimaryCategory ? [vendor.PrimaryCategory] : []);

    return rawCategories.map(normalizeCategory).filter(Boolean);
}

function getVendorPrimaryCategory(vendor) {
    const categories = getVendorCategories(vendor);
    return categories[0] || '';
}

// Create vendor card HTML
function createVendorCard(vendor) {
    const normalizedCategory = getVendorPrimaryCategory(vendor);
    const emoji = categoryEmojis[normalizedCategory] || '🔧';
    
    return `
        <div class="card-broadcast" style="cursor: pointer;" onclick="showVendorModal('${vendor.VendorID}')">
            <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 1rem;">
                <div style="flex: 1;">
                    <div style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 0.5rem;">
                        <span style="font-size: 2rem;">${emoji}</span>
                        <h3 style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.3rem; font-weight: 700; color: var(--text-primary);">
                            ${vendor.Name}
                        </h3>
                    </div>
                    ${normalizedCategory ? `
                        <div style="background: rgba(255, 102, 0, 0.1); border: 1px solid rgba(255, 102, 0, 0.3); color: var(--orange-primary); padding: 0.25rem 0.75rem; font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; font-weight: 600; letter-spacing: 0.05em; display: inline-block; margin-top: 0.5rem;">
                            ${normalizedCategory}
                        </div>
                    ` : ''}
                </div>
            </div>
            
            ${vendor.Description ? `
                <p style="color: var(--text-secondary); font-size: 0.9rem; line-height: 1.6; margin-bottom: 1rem;">
                    ${vendor.Description.length > 150 ? vendor.Description.substring(0, 150) + '...' : vendor.Description}
                </p>
            ` : ''}
            
            <div style="display: grid; gap: 0.5rem; font-size: 0.85rem; color: var(--text-muted); margin-top: 1rem;">
                ${vendor.Country ? `
                    <div style="display: flex; align-items: center;">
                        <svg style="width: 1rem; height: 1rem; margin-right: 0.5rem; color: var(--orange-primary);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                        </svg>
                        ${vendor.Country}
                    </div>
                ` : ''}
                ${vendor.Founded ? `
                    <div style="display: flex; align-items: center;">
                        <svg style="width: 1rem; height: 1rem; margin-right: 0.5rem; color: var(--orange-primary);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                        </svg>
                        Founded ${vendor.Founded}
                    </div>
                ` : ''}
            </div>
        </div>
    `;
}

// Filter vendors
function filterVendors() {
    const searchTerm = searchInput.value.toLowerCase();
    const category = categoryFilter.value;
    
    filteredVendors = allVendors.filter(vendor => {
        const matchesSearch = !searchTerm || 
            vendor.Name.toLowerCase().includes(searchTerm) ||
            (vendor.Description && vendor.Description.toLowerCase().includes(searchTerm)) ||
            (vendor.Country && vendor.Country.toLowerCase().includes(searchTerm));
        
        const vendorCategories = getVendorCategories(vendor);
        const matchesCategory = !category || vendorCategories.includes(category);
        
        return matchesSearch && matchesCategory;
    });
    
    displayVendors();
}

// Event Listeners
searchInput.addEventListener('input', filterVendors);
categoryFilter.addEventListener('change', filterVendors);

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadVendors();
});

// Modal functions
function showVendorModal(vendorId) {
    const vendor = allVendors.find(v => v.VendorID === vendorId);
    if (!vendor) return;
    
    const modal = document.getElementById('vendor-modal');
    const modalContent = document.getElementById('vendor-modal-content');
    
    const normalizedCategory = getVendorPrimaryCategory(vendor);
    const emoji = categoryEmojis[normalizedCategory] || '🔧';
    
    modalContent.innerHTML = `
        <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 2rem;">
            <div style="flex: 1;">
                <div style="display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem;">
                    <span style="font-size: 3rem;">${emoji}</span>
                    <div>
                        <h2 style="font-family: 'Barlow Condensed', sans-serif; font-size: 2.5rem; font-weight: 900; color: var(--text-primary); margin-bottom: 0.5rem;">
                            ${vendor.Name}
                        </h2>
                        ${normalizedCategory ? `
                            <div style="background: rgba(255, 102, 0, 0.1); border: 1px solid rgba(255, 102, 0, 0.3); color: var(--orange-primary); padding: 0.35rem 0.75rem; font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; font-weight: 600; letter-spacing: 0.05em; display: inline-block;">
                                ${normalizedCategory}
                            </div>
                        ` : ''}
                    </div>
                </div>
            </div>
            <button onclick="closeVendorModal()" style="background: transparent; border: none; color: var(--text-muted); cursor: pointer; padding: 0.5rem; transition: color 0.3s;" onmouseover="this.style.color='var(--text-primary)'" onmouseout="this.style.color='var(--text-muted)'">
                <svg style="width: 2rem; height: 2rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </button>
        </div>
        
        <div style="display: grid; gap: 2rem;">
            ${vendor.Description ? `
                <div>
                    <h3 style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.1rem; font-weight: 700; color: var(--orange-primary); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.75rem; display: flex; align-items: center;">
                        <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.5rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                        </svg>
                        About
                    </h3>
                    <p style="color: var(--text-secondary); line-height: 1.7; font-size: 0.95rem;">${vendor.Description}</p>
                </div>
            ` : ''}
            
            <div>
                <h3 style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.1rem; font-weight: 700; color: var(--orange-primary); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1rem; display: flex; align-items: center;">
                    <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.5rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    Quick Facts
                </h3>
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem;">
                    ${vendor.Headquarters ? `
                        <div style="background: var(--bg-card); border: 1px solid var(--border-color); padding: 1rem;">
                            <div style="font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">Headquarters</div>
                            <div style="font-size: 0.9rem; font-weight: 600; color: var(--text-primary);">${vendor.Headquarters}</div>
                        </div>
                    ` : ''}
                    ${vendor.Founded ? `
                        <div style="background: var(--bg-card); border: 1px solid var(--border-color); padding: 1rem;">
                            <div style="font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">Founded</div>
                            <div style="font-size: 0.9rem; font-weight: 600; color: var(--text-primary);">${vendor.Founded}</div>
                        </div>
                    ` : ''}
                    ${vendor.MarketPosition ? `
                        <div style="background: var(--bg-card); border: 1px solid var(--border-color); padding: 1rem; grid-column: span 2;">
                            <div style="font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">Market Position</div>
                            <div style="font-size: 0.9rem; font-weight: 600; color: var(--text-primary);">${vendor.MarketPosition}</div>
                        </div>
                    ` : ''}
                </div>
            </div>
            
            ${vendor.Products && vendor.Products.length > 0 ? `
                <div>
                    <h3 style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.1rem; font-weight: 700; color: var(--orange-primary); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1rem; display: flex; align-items: center;">
                        <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.5rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
                        </svg>
                        Products & Solutions
                    </h3>
                    <div style="display: grid; gap: 0.75rem;">
                        ${vendor.Products.map(product => `
                            <div style="display: flex; align-items: start; background: var(--bg-card); border: 1px solid var(--border-color); padding: 0.75rem;">
                                <svg style="width: 1rem; height: 1rem; margin-right: 0.75rem; margin-top: 0.1rem; color: var(--accent-green); flex-shrink: 0;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                                </svg>
                                <span style="font-size: 0.9rem; color: var(--text-secondary);">${product}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            ` : ''}
            
            ${vendor.Categories && vendor.Categories.length > 0 ? `
                <div>
                    <h3 style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.1rem; font-weight: 700; color: var(--orange-primary); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1rem; display: flex; align-items: center;">
                        <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.5rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
                        </svg>
                        All Categories
                    </h3>
                    <div style="display: flex; flex-wrap: wrap; gap: 0.5rem;">
                        ${vendor.Categories.map(cat => {
                            const normalizedCat = normalizeCategory(cat);
                            const catEmoji = categoryEmojis[normalizedCat] || '🔧';
                            return `<span style="background: rgba(255, 102, 0, 0.1); border: 1px solid rgba(255, 102, 0, 0.3); color: var(--orange-primary); padding: 0.35rem 0.75rem; font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; font-weight: 600; letter-spacing: 0.05em;">${catEmoji} ${normalizedCat}</span>`;
                        }).join('')}
                    </div>
                </div>
            ` : ''}
            
            ${vendor.Website ? `
                <div style="padding-top: 1.5rem; border-top: 1px solid var(--border-color);">
                    <a href="${vendor.Website}" target="_blank" rel="noopener noreferrer"
                       onclick="event.stopPropagation()"
                       style="display: inline-flex; align-items: center; padding: 1rem 2rem; background: var(--orange-primary); color: var(--bg-primary); font-family: 'Barlow Condensed', sans-serif; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; text-decoration: none; transition: all 0.3s; border: 2px solid var(--orange-primary);"
                       onmouseover="this.style.background='transparent'; this.style.color='var(--orange-primary)'"
                       onmouseout="this.style.background='var(--orange-primary)'; this.style.color='var(--bg-primary)'">
                        <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.75rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path>
                        </svg>
                        Visit ${vendor.Name} Website
                        <svg style="width: 1rem; height: 1rem; margin-left: 0.75rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
                        </svg>
                    </a>
                </div>
            ` : ''}
        </div>
    `;
    
    modal.classList.remove('hidden');
    document.body.style.overflow = 'hidden';
}

function closeVendorModal() {
    const modal = document.getElementById('vendor-modal');
    modal.classList.add('hidden');
    document.body.style.overflow = 'auto';
}

// Close modal on ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeVendorModal();
    }
});

// Close modal on backdrop click
document.addEventListener('click', (e) => {
    const modal = document.getElementById('vendor-modal');
    if (e.target === modal) {
        closeVendorModal();
    }
});
