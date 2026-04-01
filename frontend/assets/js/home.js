// API Configuration
const API_BASE_URL = 'https://1o8pl970wc.execute-api.eu-west-1.amazonaws.com/dev';

// Fetch and display featured vendors on homepage
async function loadFeaturedVendors() {
    try {
        const response = await fetch(`${API_BASE_URL}/vendors`);
        if (!response.ok) throw new Error('Failed to fetch vendors');
        
        const data = await response.json();
        const vendors = data.vendors || data; // Handle both formats
        
        // Pick first 3 vendors as featured
        const featured = vendors.slice(0, 3);
        
        const container = document.getElementById('featured-vendors');
        container.innerHTML = featured.map(vendor => createVendorCard(vendor, true)).join('');
        
    } catch (error) {
        console.error('Error loading featured vendors:', error);
        document.getElementById('featured-vendors').innerHTML = `
            <div class="col-span-3 text-center py-8 text-gray-600">
                <p>Unable to load featured vendors. Please try again later.</p>
            </div>
        `;
    }
}

// Create vendor card HTML
function createVendorCard(vendor, compact = false) {
    const categoryColors = {
        'Performance Tracking': 'bg-blue-100 text-blue-800',
        'Video Analysis': 'bg-purple-100 text-purple-800',
        'Data Analytics': 'bg-yellow-100 text-yellow-800',
        'Recovery': 'bg-green-100 text-green-800',
        'Fan Engagement': 'bg-pink-100 text-pink-800',
        'Facility': 'bg-indigo-100 text-indigo-800',
        'Business Operations': 'bg-orange-100 text-orange-800',
        'Scouting': 'bg-teal-100 text-teal-800',
        'Content': 'bg-red-100 text-red-800'
    };
    
    const categoryClass = categoryColors[vendor.PrimaryCategory] || 'bg-gray-100 text-gray-800';
    
    return `
        <div class="bg-white rounded-lg border border-gray-200 p-6 card-hover shadow-sm data-card">
            <div class="flex items-start justify-between mb-4">
                <h3 class="text-xl font-semibold text-gray-800">${vendor.Name}</h3>
                ${vendor.PrimaryCategory ? `
                    <span class="px-2 py-1 text-xs font-semibold rounded-full ${categoryClass}">
                        ${vendor.PrimaryCategory}
                    </span>
                ` : ''}
            </div>
            
            ${vendor.Description ? `
                <p class="text-gray-600 text-sm mb-4 line-clamp-3">${vendor.Description}</p>
            ` : ''}
            
            <div class="flex items-center justify-between text-sm text-gray-500">
                ${vendor.Country ? `
                    <span>📍 ${vendor.Country}</span>
                ` : ''}
                ${vendor.Founded ? `
                    <span>📅 ${vendor.Founded}</span>
                ` : ''}
            </div>
            
            ${vendor.Website ? `
                <div class="mt-4 pt-4 border-t border-gray-200">
                    <a href="${vendor.Website}" target="_blank" rel="noopener noreferrer"
                       class="text-euroleague-orange hover:text-orange-700 font-medium text-sm">
                        Learn More →
                    </a>
                </div>
            ` : ''}
        </div>
    `;
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    loadFeaturedVendors();
});
