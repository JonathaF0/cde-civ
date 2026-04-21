// CDECAD Civilian Manager - ID Card NUI Script

let hideTimeout = null;

// Listen for messages from the client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'showID') {
        showIDCard(data.civilian, data.from, data.duration, data.style, data.apiConfig);
    } else if (data.action === 'hideID') {
        hideIDCard();
    }
});

// Show the ID card
function showIDCard(civilian, from, duration, style, apiConfig) {
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
    
    var photoContainer = document.getElementById('civilian-photo');
    if (!photoContainer) return;

    var mugshotUrl = civilian.mugshotUrl;
    var ssn = civilian.ssn || civilian.citizenid;

    if (mugshotUrl && mugshotUrl.startsWith('data:')) {
        // Self-contained data URI — display directly, no network needed
        renderMugshot(photoContainer, mugshotUrl);
    } else if (ssn && apiConfig && apiConfig.url) {
        // Fetch fresh from the CAD API — handles HTTP URLs, converts to compressed
        // data URI, and is the source of truth for the photo.
        photoContainer.innerHTML = '<span class="no-photo" style="font-size:9px;color:#6b7280">LOADING...</span>';
        fetch(apiConfig.url + '/civilian/fivem-civilian/' + ssn + '?communityId=' + apiConfig.communityId, {
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': apiConfig.key
            }
        })
        .then(function(r) { return r.ok ? r.json() : null; })
        .then(function(data) {
            var el = document.getElementById('civilian-photo');
            if (!el) return;
            if (data && data.mugshotUrl) {
                renderMugshot(el, data.mugshotUrl);
            } else {
                el.innerHTML = '<span class="no-photo">NO PHOTO</span>';
            }
        })
        .catch(function() {
            var el = document.getElementById('civilian-photo');
            if (el) el.innerHTML = '<span class="no-photo">NO PHOTO</span>';
        });
    } else if (mugshotUrl) {
        // HTTP URL with no API config — try direct (may fail due to CORS/expiry)
        renderMugshot(photoContainer, mugshotUrl);
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

function renderMugshot(container, value) {
    const src = normaliseMugshotSrc(value);
    container.innerHTML = '';
    const img = document.createElement('img');
    img.alt = 'Photo';
    img.onerror = function() {
        // Guard: img may have been removed from DOM if showIDCard was called twice rapidly
        var parent = this.parentElement;
        if (parent) parent.innerHTML = '<span class="no-photo">NO PHOTO</span>';
    };
    img.src = src;
    container.appendChild(img);
}

// Normalise a mugshot value to a usable <img src> string.
// MugShotBase64 returns raw base64 data with no prefix.
// JPEG base64 starts with "/9j/" — PNG starts with "iVBOR".
// Using the wrong MIME type makes the browser reject the image and fires onerror.
function normaliseMugshotSrc(value) {
    if (!value) return '';
    // Already a valid data URI or a remote URL — use as-is
    if (value.startsWith('data:') || value.startsWith('http://') || value.startsWith('https://')) {
        return value;
    }
    // Detect format from base64 header bytes
    const mime = value.startsWith('/9j') ? 'image/jpeg' : 'image/png';
    return `data:${mime};base64,` + value;
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
        if (!document.getElementById('bank-panel').classList.contains('hidden')) {
            closeBank();
            return;
        }
        hideIDCard();
        fetch(`https://${GetParentResourceName()}/escape`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// BANK PANEL
// ─────────────────────────────────────────────────────────────────────────────

let bankCivilianId  = null;
let bankCommunityId = null;
let bankPlayerCash  = null; // available in-game cash; null = unknown

// NUI message handler picks up openBank action
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'openBank') {
        openBank(data.account, data.civilian, data.communityId, data.playerCash);
    }
});

function nuiFetch(endpoint, payload) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload || {})
    }).then(r => r.json()).catch(() => ({ success: false, error: 'Request failed' }));
}

function openBank(account, civilian, communityId, playerCash) {
    bankCivilianId  = civilian.id;
    bankCommunityId = communityId;
    bankPlayerCash  = (typeof playerCash === 'number') ? playerCash : null;

    document.getElementById('bank-civ-name').textContent =
        (civilian.firstName || '') + ' ' + (civilian.lastName || '');
    document.getElementById('bank-account-num').textContent =
        account.accountNumber || 'ACC---------';
    document.getElementById('bank-status-badge').textContent =
        (account.accountStatus || 'active').toUpperCase();

    // Show available cash in deposit tab
    const cashEl = document.getElementById('deposit-cash-available');
    if (cashEl) {
        cashEl.textContent = bankPlayerCash !== null
            ? '$' + bankPlayerCash.toLocaleString('en-US', { minimumFractionDigits: 2 })
            : '—';
    }

    updateBalance(account.balance || 0);
    renderTransactions(account.transactions || []);

    showTab('transactions');
    document.getElementById('bank-panel').classList.remove('hidden');
}

function closeBank() {
    document.getElementById('bank-panel').classList.add('hidden');
    nuiFetch('closeBank', {});
}

function updateBalance(amount) {
    const el = document.getElementById('bank-balance');
    el.textContent = '$' + Number(amount).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
    el.style.color = amount < 0 ? '#ef4444' : '#10b981';
}

function renderTransactions(txs) {
    const list = document.getElementById('transaction-list');
    if (!txs || txs.length === 0) {
        list.innerHTML = '<div class="tx-empty">No transactions yet</div>';
        return;
    }

    const iconMap = {
        deposit:    { cls: 'deposit',    sym: '↓' },
        withdrawal: { cls: 'withdrawal', sym: '↑' },
        transfer:   { cls: 'transfer',   sym: '⇄' },
        fine:       { cls: 'fine',       sym: '!' },
        ticket:     { cls: 'fine',       sym: '!' },
        salary:     { cls: 'salary',     sym: '★' },
        payment:    { cls: 'transfer',   sym: '⇄' },
    };

    const creditTypes = ['deposit', 'salary'];

    const rows = [...txs].reverse().slice(0, 50).map(tx => {
        const info = iconMap[tx.type] || { cls: 'transfer', sym: '•' };
        const isCredit = creditTypes.includes(tx.type);
        const amtClass = isCredit ? 'plus' : 'minus';
        const amtSign  = isCredit ? '+' : '-';
        const amtStr   = amtSign + '$' + Number(tx.amount).toLocaleString('en-US', { minimumFractionDigits: 2 });
        const dateStr  = tx.date ? new Date(tx.date).toLocaleString('en-US', { month:'short', day:'numeric', hour:'2-digit', minute:'2-digit' }) : '';

        return `<div class="tx-item">
            <div class="tx-icon ${info.cls}">${info.sym}</div>
            <div class="tx-body">
                <div class="tx-desc">${esc(tx.description || tx.type)}</div>
                <div class="tx-date">${esc(dateStr)}</div>
            </div>
            <div class="tx-amount ${amtClass}">${amtStr}</div>
        </div>`;
    });

    list.innerHTML = rows.join('');
}

function esc(str) {
    if (str == null) return '';
    const d = document.createElement('div');
    d.textContent = String(str);
    return d.innerHTML;
}

function showTab(name) {
    document.querySelectorAll('.bank-tab').forEach(t => t.classList.add('hidden'));
    document.querySelectorAll('.bank-nav-btn').forEach(b => b.classList.remove('active'));
    const tab = document.getElementById('tab-' + name);
    if (tab) tab.classList.remove('hidden');
    const btn = document.querySelector(`.bank-nav-btn[data-tab="${name}"]`);
    if (btn) btn.classList.add('active');
}

function showMsg(id, type, text) {
    const el = document.getElementById(id);
    if (!el) return;
    el.className = 'form-msg ' + type;
    el.textContent = text;
    setTimeout(() => { el.className = 'form-msg hidden'; }, 4000);
}

// Nav tab switching
document.querySelectorAll('.bank-nav-btn').forEach(btn => {
    btn.addEventListener('click', () => showTab(btn.dataset.tab));
});

// Close button
document.getElementById('bank-close').addEventListener('click', closeBank);

// Refresh transactions
document.getElementById('btn-refresh').addEventListener('click', async function() {
    if (!bankCivilianId) return;
    this.style.opacity = '0.4';
    const res = await nuiFetch('bankDeposit', { civilianId: bankCivilianId, amount: 0, description: '' });
    // We re-open with updated data — just reload via callback
    this.style.opacity = '1';
});

// Deposit
document.getElementById('btn-deposit').addEventListener('click', async function() {
    const amount = parseFloat(document.getElementById('deposit-amount').value);
    const desc   = document.getElementById('deposit-desc').value.trim();

    if (!amount || amount <= 0) { showMsg('deposit-msg', 'error', 'Enter a valid amount'); return; }
    if (!desc)                  { showMsg('deposit-msg', 'error', 'Enter a description');  return; }

    // Client-side cash guard — server also validates this independently
    if (bankPlayerCash !== null && amount > bankPlayerCash) {
        showMsg('deposit-msg', 'error',
            'Insufficient cash. You have $' +
            bankPlayerCash.toLocaleString('en-US', { minimumFractionDigits: 2 }) + ' available.');
        return;
    }

    this.disabled = true;
    const res = await nuiFetch('bankDeposit', { civilianId: bankCivilianId, amount, description: desc });
    this.disabled = false;

    if (res && res.success) {
        updateBalance(res.balance);
        showMsg('deposit-msg', 'success', 'Deposit successful! New balance: $' + Number(res.balance).toLocaleString('en-US', { minimumFractionDigits: 2 }));
        document.getElementById('deposit-amount').value = '';
        document.getElementById('deposit-desc').value = '';
        // Subtract from locally tracked cash
        if (bankPlayerCash !== null) {
            bankPlayerCash = Math.max(0, bankPlayerCash - amount);
            const cashEl = document.getElementById('deposit-cash-available');
            if (cashEl) cashEl.textContent = '$' + bankPlayerCash.toLocaleString('en-US', { minimumFractionDigits: 2 });
        }
        if (res.transaction) {
            const list = document.getElementById('transaction-list');
            if (list.querySelector('.tx-empty')) list.innerHTML = '';
            list.insertAdjacentHTML('afterbegin', buildTxRow(res.transaction));
        }
    } else {
        showMsg('deposit-msg', 'error', (res && res.error) || 'Deposit failed');
    }
});

// Withdraw
document.getElementById('btn-withdraw').addEventListener('click', async function() {
    const amount = parseFloat(document.getElementById('withdraw-amount').value);
    const desc   = document.getElementById('withdraw-desc').value.trim();

    if (!amount || amount <= 0) { showMsg('withdraw-msg', 'error', 'Enter a valid amount'); return; }
    if (!desc)                  { showMsg('withdraw-msg', 'error', 'Enter a description');  return; }

    this.disabled = true;
    const res = await nuiFetch('bankWithdraw', { civilianId: bankCivilianId, amount, description: desc });
    this.disabled = false;

    if (res && res.success) {
        updateBalance(res.balance);
        showMsg('withdraw-msg', 'success', 'Withdrawal successful! New balance: $' + Number(res.balance).toLocaleString('en-US', { minimumFractionDigits: 2 }));
        document.getElementById('withdraw-amount').value = '';
        document.getElementById('withdraw-desc').value = '';
        if (res.transaction) {
            const list = document.getElementById('transaction-list');
            if (list.querySelector('.tx-empty')) list.innerHTML = '';
            list.insertAdjacentHTML('afterbegin', buildTxRow(res.transaction));
        }
    } else {
        showMsg('withdraw-msg', 'error', (res && res.error) || 'Withdrawal failed');
    }
});

// Transfer
document.getElementById('btn-transfer').addEventListener('click', async function() {
    const toAcct  = document.getElementById('transfer-to').value.trim();
    const amount  = parseFloat(document.getElementById('transfer-amount').value);
    const desc    = document.getElementById('transfer-desc').value.trim();

    if (!toAcct)                { showMsg('transfer-msg', 'error', 'Enter recipient account number'); return; }
    if (!amount || amount <= 0) { showMsg('transfer-msg', 'error', 'Enter a valid amount');            return; }
    if (!desc)                  { showMsg('transfer-msg', 'error', 'Enter a description');             return; }

    this.disabled = true;
    const res = await nuiFetch('bankTransfer', {
        fromCivilianId: bankCivilianId,
        toAccountNumber: toAcct,
        amount,
        description: desc
    });
    this.disabled = false;

    if (res && res.success) {
        updateBalance(res.balance);
        showMsg('transfer-msg', 'success', 'Transfer sent! New balance: $' + Number(res.balance).toLocaleString('en-US', { minimumFractionDigits: 2 }));
        document.getElementById('transfer-to').value = '';
        document.getElementById('transfer-amount').value = '';
        document.getElementById('transfer-desc').value = '';
        if (res.transaction) {
            const list = document.getElementById('transaction-list');
            if (list.querySelector('.tx-empty')) list.innerHTML = '';
            list.insertAdjacentHTML('afterbegin', buildTxRow(res.transaction));
        }
    } else {
        showMsg('transfer-msg', 'error', (res && res.error) || 'Transfer failed');
    }
});

function buildTxRow(tx) {
    const creditTypes = ['deposit', 'salary'];
    const iconMap = {
        deposit:    { cls: 'deposit',    sym: '↓' },
        withdrawal: { cls: 'withdrawal', sym: '↑' },
        transfer:   { cls: 'transfer',   sym: '⇄' },
        fine:       { cls: 'fine',       sym: '!' },
        ticket:     { cls: 'fine',       sym: '!' },
        salary:     { cls: 'salary',     sym: '★' },
        payment:    { cls: 'transfer',   sym: '⇄' },
    };
    const info = iconMap[tx.type] || { cls: 'transfer', sym: '•' };
    const isCredit = creditTypes.includes(tx.type);
    const amtClass = isCredit ? 'plus' : 'minus';
    const amtSign  = isCredit ? '+' : '-';
    const amtStr   = amtSign + '$' + Number(tx.amount).toLocaleString('en-US', { minimumFractionDigits: 2 });
    const dateStr  = tx.date ? new Date(tx.date).toLocaleString('en-US', { month:'short', day:'numeric', hour:'2-digit', minute:'2-digit' }) : '';
    return `<div class="tx-item">
        <div class="tx-icon ${info.cls}">${info.sym}</div>
        <div class="tx-body">
            <div class="tx-desc">${esc(tx.description || tx.type)}</div>
            <div class="tx-date">${esc(dateStr)}</div>
        </div>
        <div class="tx-amount ${amtClass}">${amtStr}</div>
    </div>`;
}
