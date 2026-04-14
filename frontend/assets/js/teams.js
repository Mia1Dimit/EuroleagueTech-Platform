// API Configuration
const API_BASE_URL = 'https://1o8pl970wc.execute-api.eu-west-1.amazonaws.com/dev';

// State
let allTeams = [];
let filteredTeams = [];
const teamDetailsCache = new Map();

// DOM Elements
const searchInput = document.getElementById('search-input');
const countryFilter = document.getElementById('country-filter');
const teamsList = document.getElementById('teams-list');
const resultsCount = document.getElementById('results-count');
const loading = document.getElementById('loading');
const error = document.getElementById('error');
const noResults = document.getElementById('no-results');
const teamsHeadlineCount = document.getElementById('teams-headline-count');
const teamsHeadlineCountryCount = document.getElementById('teams-headline-country-count');

// Fetch teams from API
async function loadTeams() {
    try {
        loading.classList.remove('hidden');
        error.classList.add('hidden');
        
        const response = await fetch(`${API_BASE_URL}/teams`);
        if (!response.ok) throw new Error('Failed to fetch teams');
        
        const data = await response.json();
        // API returns {count: 20, teams: [...]} not direct array
        allTeams = data.teams || data.Teams || data; // Handle both formats
        filteredTeams = [...allTeams];

        updateTeamsHeadlineMetrics();
        
        populateCountryFilter();
        loading.classList.add('hidden');
        displayTeams();
        
    } catch (err) {
        console.error('Error loading teams:', err);
        loading.classList.add('hidden');
        error.classList.remove('hidden');
    }
}

function updateTeamsHeadlineMetrics() {
    if (teamsHeadlineCount) {
        teamsHeadlineCount.textContent = allTeams.length;
    }

    if (teamsHeadlineCountryCount) {
        const uniqueCountries = new Set(allTeams.map(team => team.Country).filter(Boolean));
        teamsHeadlineCountryCount.textContent = uniqueCountries.size;
    }
}

// Populate country filter dropdown
function populateCountryFilter() {
    const countries = [...new Set(allTeams.map(team => team.Country))].sort();
    
    countryFilter.innerHTML = '<option value="">All Countries</option>' +
        countries.map(country => `<option value="${country}">${country}</option>`).join('');
}

// Display teams
function displayTeams() {
    if (filteredTeams.length === 0) {
        teamsList.classList.add('hidden');
        noResults.classList.remove('hidden');
        resultsCount.textContent = '0';
        return;
    }
    
    teamsList.classList.remove('hidden');
    noResults.classList.add('hidden');
    
    teamsList.innerHTML = filteredTeams.map(team => createTeamCard(team)).join('');
    resultsCount.textContent = filteredTeams.length;
}

// Create team card HTML
function createTeamCard(team) {
    // Country flag emoji mapping - handles both full names and abbreviations
    const flagEmoji = {
        'Germany': '🇩🇪',
        'Spain': '🇪🇸',
        'Greece': '🇬🇷',
        'Turkey': '🇹🇷',
        'France': '🇫🇷',
        'Italy': '🇮🇹',
        'Lithuania': '🇱🇹',
        'Serbia': '🇷🇸',
        'Israel': '🇮🇱',
        'Monaco': '🇲🇨',
        'UAE': '🇦🇪',
        'United Arab Emirates': '🇦🇪'
    };
    
    const flag = flagEmoji[team.Country] || '🏀';
    
    return `
        <div class="card-broadcast" style="cursor: pointer;" onclick="showTeamModal('${team.TeamID}')">
            <div style="text-align: center; font-size: 3rem; margin-bottom: 1rem;">${flag}</div>
            
            <h3 style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.3rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; text-align: center;">
                ${team.Name}
            </h3>
            
            ${team.City ? `
                <p style="text-align: center; color: var(--text-secondary); font-size: 0.9rem; margin-bottom: 1rem;">${team.City}</p>
            ` : ''}
            
            <div style="font-size: 0.85rem; color: var(--text-muted); space-y: 0.5rem;">
                ${team.Arena ? `
                    <div style="display: flex; align-items: start; margin-bottom: 0.5rem;">
                        <svg style="width: 1rem; height: 1rem; margin-right: 0.5rem; margin-top: 0.1rem; color: var(--orange-primary); flex-shrink: 0;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                        </svg>
                        <span style="flex: 1;">${team.Arena}</span>
                    </div>
                ` : ''}
                ${team.Country ? `
                    <div style="display: flex; align-items: center;">
                        <svg style="width: 1rem; height: 1rem; margin-right: 0.5rem; color: var(--orange-primary);" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9"></path>
                        </svg>
                        ${team.Country}
                    </div>
                ` : ''}
            </div>
            
            ${team.Website ? `
                <div style="margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid var(--border-color);">
                    <div style="color: var(--orange-primary); font-family: 'Barlow Condensed', sans-serif; font-weight: 600; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.05em; display: flex; align-items: center; justify-content: center;">
                        Team Website
                        <svg style="width: 0.9rem; height: 0.9rem; margin-left: 0.4rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
                        </svg>
                    </div>
                </div>
            ` : ''}
        </div>
    `;
}

// Filter teams
function filterTeams() {
    const searchTerm = searchInput.value.toLowerCase();
    const country = countryFilter.value;
    
    filteredTeams = allTeams.filter(team => {
        const matchesSearch = !searchTerm || 
            team.Name.toLowerCase().includes(searchTerm) ||
            (team.City && team.City.toLowerCase().includes(searchTerm)) ||
            (team.Arena && team.Arena.toLowerCase().includes(searchTerm)) ||
            (team.Country && team.Country.toLowerCase().includes(searchTerm));
        
        const matchesCountry = !country || team.Country === country;
        
        return matchesSearch && matchesCountry;
    });
    
    displayTeams();
}

// Event Listeners
searchInput.addEventListener('input', filterTeams);
countryFilter.addEventListener('change', filterTeams);

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadTeams();
});

// Modal functions
async function fetchTeamDetails(teamId) {
    if (teamDetailsCache.has(teamId)) {
        return teamDetailsCache.get(teamId);
    }

    const response = await fetch(`${API_BASE_URL}/teams/${teamId}`);
    if (!response.ok) {
        throw new Error(`Failed to fetch team details for ${teamId}`);
    }

    const team = await response.json();
    teamDetailsCache.set(teamId, team);
    return team;
}

function getPartnershipMetadata(team, partnerName) {
    const metadata = team.PartnershipMetadata || {};
    return metadata[partnerName] || null;
}

function createPartnershipCard(partnerName, metadata) {
    const confidence = metadata?.AdoptionConfidence || metadata?.adoptionConfidence;
    const startYear = metadata?.AdoptionStartYear || metadata?.adoptionStartYear;
    const source = metadata?.ConfirmationSource || metadata?.confirmationSource;

    return `
        <div style="background: var(--bg-card); border: 1px solid var(--border-color); padding: 0.75rem;">
            <div style="display: flex; align-items: center; margin-bottom: 0.35rem;">
                <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.75rem; color: var(--accent-green); flex-shrink: 0;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
                <span style="font-size: 0.9rem; font-weight: 600; color: var(--text-secondary);">${partnerName}</span>
            </div>
            ${startYear || confidence || source ? `
                <div style="margin-left: 2rem; font-size: 0.8rem; color: var(--text-muted); display: flex; flex-wrap: wrap; gap: 0.65rem;">
                    ${startYear ? `<span>Start: <strong style="color: var(--text-secondary);">${startYear}</strong></span>` : ''}
                    ${confidence ? `<span>Confidence: <strong style="color: var(--text-secondary);">${confidence}</strong></span>` : ''}
                    ${source ? `<a href="${source}" target="_blank" rel="noopener noreferrer" onclick="event.stopPropagation()" style="color: var(--orange-primary); text-decoration: none;">Source ↗</a>` : ''}
                </div>
            ` : ''}
        </div>
    `;
}

async function showTeamModal(teamId) {
    const summaryTeam = allTeams.find(t => t.TeamID === teamId);
    if (!summaryTeam) return;

    let team = summaryTeam;
    try {
        team = await fetchTeamDetails(teamId);
    } catch (err) {
        console.error('Could not load detailed team data, falling back to summary:', err);
    }
    
    const modal = document.getElementById('team-modal');
    const modalContent = document.getElementById('team-modal-content');
    
    const flagEmoji = {
        'Germany': '🇩🇪',
        'Spain': '🇪🇸',
        'Greece': '🇬🇷',
        'Turkey': '🇹🇷',
        'France': '🇫🇷',
        'Italy': '🇮🇹',
        'Lithuania': '🇱🇹',
        'Serbia': '🇷🇸',
        'Israel': '🇮🇱',
        'Monaco': '🇲🇨',
        'UAE': '🇦🇪',
        'United Arab Emirates': '🇦🇪'
    };
    const flag = flagEmoji[team.Country] || '🏀';
    
    modalContent.innerHTML = `
        <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 2rem;">
            <div style="flex: 1;">
                <div style="display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem;">
                    <span style="font-size: 3.5rem;">${flag}</span>
                    <div>
                        <h2 style="font-family: 'Barlow Condensed', sans-serif; font-size: 2.5rem; font-weight: 900; color: var(--text-primary); margin-bottom: 0.5rem;">
                            ${team.Name}
                        </h2>
                        <p style="font-size: 1rem; color: var(--text-secondary); font-family: 'Outfit', sans-serif; margin-top: 0.25rem;">
                            ${team.City ? team.City + ', ' : ''}${team.Country}
                        </p>
                    </div>
                </div>
            </div>
            <button onclick="closeTeamModal()" style="background: transparent; border: none; color: var(--text-muted); cursor: pointer; padding: 0.5rem; transition: color 0.3s;" onmouseover="this.style.color='var(--text-primary)'" onmouseout="this.style.color='var(--text-muted)'">
                <svg style="width: 2rem; height: 2rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </button>
        </div>
        
        <div style="display: grid; gap: 2rem;">
            <div>
                <h3 style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.1rem; font-weight: 700; color: var(--orange-primary); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1rem; display: flex; align-items: center;">
                    <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.5rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    Team Information
                </h3>
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem;">
                    ${team.Arena ? `
                        <div style="background: var(--bg-card); border: 1px solid var(--border-color); padding: 1rem;">
                            <div style="font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">Home Arena</div>
                            <div style="font-size: 0.9rem; font-weight: 600; color: var(--text-primary);">${team.Arena}</div>
                        </div>
                    ` : ''}
                    ${team.ArenaCapacity ? `
                        <div style="background: var(--bg-card); border: 1px solid var(--border-color); padding: 1rem;">
                            <div style="font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">Arena Capacity</div>
                            <div style="font-size: 0.9rem; font-weight: 600; color: var(--text-primary);">${team.ArenaCapacity.toLocaleString()} seats</div>
                        </div>
                    ` : ''}
                    ${team.EuroleagueStatus ? `
                        <div style="background: var(--bg-card); border: 1px solid var(--border-color); padding: 1rem; grid-column: span 2;">
                            <div style="font-family: 'JetBrains Mono', monospace; font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.5rem; text-transform: uppercase; letter-spacing: 0.05em;">Euroleague Status</div>
                            <div style="font-size: 0.9rem; font-weight: 600; color: var(--text-primary);">${team.EuroleagueStatus}</div>
                        </div>
                    ` : ''}
                </div>
            </div>
            
            ${team.Partnerships && team.Partnerships.length > 0 ? `
                <div>
                    <h3 style="font-family: 'Barlow Condensed', sans-serif; font-size: 1.1rem; font-weight: 700; color: var(--orange-primary); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1rem; display: flex; align-items: center;">
                        <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.5rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                        </svg>
                        Technology Partnerships
                    </h3>
                    <div style="display: grid; gap: 0.75rem;">
                        ${team.Partnerships.map(partner => createPartnershipCard(partner, getPartnershipMetadata(team, partner))).join('')}
                    </div>
                </div>
            ` : `
                <div style="background: rgba(251, 191, 36, 0.1); border: 1px solid rgba(251, 191, 36, 0.3); padding: 1.5rem;">
                    <div style="display: flex; align-items: start;">
                        <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.75rem; margin-top: 0.1rem; color: var(--accent-yellow); flex-shrink: 0;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                        <div>
                            <h4 style="font-family: 'Barlow Condensed', sans-serif; font-size: 0.9rem; font-weight: 700; color: var(--accent-yellow); margin-bottom: 0.5rem; text-transform: uppercase;">Technology Partnerships</h4>
                            <p style="font-size: 0.9rem; color: var(--text-secondary); line-height: 1.5;">No public technology partnerships documented yet. Check back for updates as we continue researching team technology stacks.</p>
                        </div>
                    </div>
                </div>
            `}
            
            ${team.Website ? `
                <div style="padding-top: 1.5rem; border-top: 1px solid var(--border-color);">
                    <a href="${team.Website}" target="_blank" rel="noopener noreferrer"
                       onclick="event.stopPropagation()"
                       style="display: inline-flex; align-items: center; padding: 1rem 2rem; background: var(--orange-primary); color: var(--bg-primary); font-family: 'Barlow Condensed', sans-serif; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; text-decoration: none; transition: all 0.3s; border: 2px solid var(--orange-primary);"
                       onmouseover="this.style.background='transparent'; this.style.color='var(--orange-primary)'"
                       onmouseout="this.style.background='var(--orange-primary)'; this.style.color='var(--bg-primary)'">
                        <svg style="width: 1.25rem; height: 1.25rem; margin-right: 0.75rem;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path>
                        </svg>
                        Visit ${team.Name} Website
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

function closeTeamModal() {
    const modal = document.getElementById('team-modal');
    modal.classList.add('hidden');
    document.body.style.overflow = 'auto';
}

// Close modal on ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeTeamModal();
    }
});

// Close modal on backdrop click
document.addEventListener('click', (e) => {
    const modal = document.getElementById('team-modal');
    if (e.target === modal) {
        closeTeamModal();
    }
});
