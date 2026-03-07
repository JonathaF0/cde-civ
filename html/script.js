// CDECAD Civilian Manager - ID Card NUI Script

let hideTimeout = null;

// Listen for messages from the client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'showID') {
        showIDCard(data.civilian, data.from, data.duration, data.style);
    } else if (data.action === 'hideID') {
        hideIDCard();
    }
});

// Show the ID card
function showIDCard(civilian, from, duration, style) {
    // Clear any existing timeout first
    if (hideTimeout) {
        clearTimeout(hideTimeout);
        hideTimeout = null;
    }
    
    const container = document.getElementById('id-card-container');
    const card = document.getElementById('id-card');
    
    // Reset animation
    container.style.animation = 'none';
    container.offsetHeight; // Trigger reflow
    
    // Apply custom styles if provided
    if (style) {
        if (style.BackgroundColor) {
            card.style.background = `linear-gradient(135deg, ${style.BackgroundColor} 0%, ${lightenColor(style.BackgroundColor, 20)} 50%, ${style.BackgroundColor} 100%)`;
        }
        if (style.StateName) {
            document.querySelector('.state-name').textContent = style.StateName.toUpperCase();
        }
        if (style.CardTitle) {
            document.querySelector('.card-title').textContent = style.CardTitle;
        }
    } else {
        // Reset to defaults if no style provided
        document.querySelector('.state-name').textContent = 'SAN ANDREAS';
        document.querySelector('.card-title').textContent = 'DRIVER LICENSE';
    }
    
    // Clear all fields first to prevent stale data
    document.getElementById('civ-ssn').textContent = '-';
    document.getElementById('civ-name').textContent = '-';
    document.getElementById('civ-dob').textContent = '-';
    document.getElementById('civ-sex').textContent = '-';
    document.getElementById('civ-eyes').textContent = '-';
    document.getElementById('civ-height').textContent = '-';
    document.getElementById('civ-weight').textContent = '-';
    document.getElementById('civ-address').textContent = '-';
    document.getElementById('shown-by').textContent = '';
    document.getElementById('civilian-signature').textContent = '';
    
    // Now populate with new civilian data
    document.getElementById('civ-ssn').textContent = civilian.ssn || civilian.citizenid || 'N/A';
    document.getElementById('civ-name').textContent = `${civilian.lastName || ''}, ${civilian.firstName || ''}`.toUpperCase();
    document.getElementById('civ-dob').textContent = formatDate(civilian.dob || civilian.dateOfBirth);
    document.getElementById('civ-sex').textContent = formatGender(civilian.gender);
    document.getElementById('civ-eyes').textContent = (civilian.eyeColor || 'BRN').toUpperCase().substring(0, 3);
    document.getElementById('civ-height').textContent = civilian.height || "5'10\"";
    document.getElementById('civ-weight').textContent = civilian.weight ? `${civilian.weight} lbs` : '180 lbs';
    document.getElementById('civ-address').textContent = civilian.address || 'Los Santos, SA';
    document.getElementById('shown-by').textContent = `Shown by: ${from}`;
    
    // Set signature
    document.getElementById('civilian-signature').textContent = `${civilian.firstName || ''} ${civilian.lastName || ''}`;
    
    // Set photo if available
    const photoContainer = document.getElementById('civilian-photo');
    if (civilian.mugshotUrl || civilian.photoUrl) {
        photoContainer.innerHTML = `<img src="${civilian.mugshotUrl || civilian.photoUrl}" alt="Photo" onerror="this.parentElement.innerHTML='<span class=\\'no-photo\\'>NO PHOTO</span>'">`;
    } else {
        photoContainer.innerHTML = '<span class="no-photo">NO PHOTO</span>';
    }
    
    // Show the card
    container.classList.remove('hidden');
    container.style.animation = 'fadeIn 0.3s ease-out';
    
    // Auto-hide after duration
    hideTimeout = setTimeout(function() {
        hideIDCard();
    }, duration || 10000);
    
    console.log('[CDECAD-CIVMANAGER] Showing ID for:', civilian.firstName, civilian.lastName);
}

// Hide the ID card
function hideIDCard() {
    const container = document.getElementById('id-card-container');
    container.style.animation = 'fadeOut 0.3s ease-out';
    
    setTimeout(function() {
        container.classList.add('hidden');
    }, 300);
    
    // Notify client
    fetch(`https://${GetParentResourceName()}/closeID`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Format date for display
function formatDate(dateStr) {
    if (!dateStr) return 'N/A';
    
    try {
        const date = new Date(dateStr);
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const year = date.getFullYear();
        return `${month}/${day}/${year}`;
    } catch (e) {
        return dateStr;
    }
}

// Format gender for display
function formatGender(gender) {
    if (!gender) return 'U';
    
    const g = gender.toString().toLowerCase();
    if (g === 'male' || g === 'm' || g === '0') return 'M';
    if (g === 'female' || g === 'f' || g === '1') return 'F';
    return 'X';
}

// Lighten a hex color
function lightenColor(color, percent) {
    if (!color) return '#2c5282';
    
    // Remove # if present
    color = color.replace('#', '');
    
    // Parse RGB
    let r = parseInt(color.substring(0, 2), 16);
    let g = parseInt(color.substring(2, 4), 16);
    let b = parseInt(color.substring(4, 6), 16);
    
    // Lighten
    r = Math.min(255, Math.floor(r + (255 - r) * (percent / 100)));
    g = Math.min(255, Math.floor(g + (255 - g) * (percent / 100)));
    b = Math.min(255, Math.floor(b + (255 - b) * (percent / 100)));
    
    // Convert back to hex
    return '#' + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

// Close on click
document.addEventListener('click', function(e) {
    if (e.target.closest('#id-card-container')) {
        hideIDCard();
    }
});

// Close on escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        hideIDCard();
        fetch(`https://${GetParentResourceName()}/escape`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});
