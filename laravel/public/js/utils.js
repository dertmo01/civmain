// ============================================================
// CIVILWATCH Admin Dashboard — Utilities
// ============================================================

const Utils = {

    // ── Output escaping (XSS) ─────────────────────────────────────────
    // Every value that comes from the API, the URL or localStorage — report
    // concern/description, citizen name/phone/address, barangay, notification
    // text, office names, notes — MUST pass through one of these before it is
    // put into innerHTML, insertAdjacentHTML, a template string that becomes
    // HTML, or a Leaflet bindPopup/bindTooltip string. Citizens control most
    // of that text, and the panel holds a staff bearer token in localStorage.

    // HTML text and quoted attribute values.
    esc(value) {
        return String(value ?? '').replace(/[&<>"'`]/g, c => ({
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#39;',
            '`': '&#96;',
        }[c]));
    },

    // A JS string literal for use INSIDE an inline handler attribute, e.g.
    //   onclick="openReport(${Utils.jsArg(r.ref)})"
    // JSON.stringify makes a valid JS string; esc() then stops the browser's
    // HTML-attribute decoding from turning &#39; back into a quote.
    jsArg(value) {
        return Utils.esc(JSON.stringify(String(value ?? '')));
    },

    // Escaped URL for src/href. Allows http(s)://, data:image/*, and relative
    // paths (e.g. /storage/report-photos/x.jpg). Anything else — javascript:,
    // data:text/html, protocol-relative //host — becomes ''.
    safeUrl(value) {
        const s = String(value ?? '').trim();
        if (!s) return '';
        if (/^https?:\/\//i.test(s)) return Utils.esc(s);
        if (/^data:image\/(png|jpe?g|gif|webp);/i.test(s)) return Utils.esc(s);
        if (/^[a-z][a-z0-9+.-]*:/i.test(s) || s.startsWith('//') || s.startsWith('\\')) return '';
        return Utils.esc(s);
    },

    // Format date string
    formatDate(dateStr) {
        return dateStr || '—';
    },

    // Canonical status colours — single source of truth for status pins,
    // legend chips and analytics (mirrors STATUS_ORDER on the API).
    STATUS_COLORS: {
        'Submitted': '#9CA3AF',
        'Pending Validation': '#F59E0B',
        'Approved': '#0E7C7B',
        'Assigned to Office': '#1A56DB',
        'Assigned': '#1A56DB', // short-label alias
        'In Progress': '#7C3AED',
        'Resolved': '#10B981',
        'Rejected': '#EF4444',
    },

    // Get status badge HTML
    statusBadge(status) {
        const map = {
            'Submitted': {
                cls: 'badge-submitted',
                icon: 'schedule_send',
                label: 'Submitted'
            },
            'Pending Validation': {
                cls: 'badge-validation',
                icon: 'schedule',
                label: 'Pending Validation'
            },
            'Approved': {
                cls: 'badge-approved',
                icon: 'verified',
                label: 'Approved'
            },
            'Assigned to Office': {
                cls: 'badge-assigned',
                icon: 'assignment_ind',
                label: 'Assigned'
            },
            'Assigned': {
                cls: 'badge-assigned',
                icon: 'assignment_ind',
                label: 'Assigned'
            },
            'In Progress': {
                cls: 'badge-inprogress',
                icon: 'autorenew',
                label: 'In Progress'
            },
            'Resolved': {
                cls: 'badge-resolved',
                icon: 'check_circle',
                label: 'Resolved'
            },
            'Rejected': {
                cls: 'badge-rejected',
                icon: 'cancel',
                label: 'Rejected'
            },
        };
        const s = map[status] || {
            cls: 'badge-pending',
            icon: 'help',
            label: status
        };
        return `<span class="badge ${s.cls}"><span class="material-symbols-outlined">${s.icon}</span>${Utils.esc(s.label)}</span>`;
    },

    // Get category badge HTML — canonical API value 'Environment' displays as
    // 'Environmental'; 'Others' keeps its own badge instead of being mislabeled.
    categoryBadge(category) {
        const labels = {
            'Infrastructure': {
                cls: 'badge-infra',
                icon: 'construction',
                label: 'Infrastructure'
            },
            'Environment': {
                cls: 'badge-env',
                icon: 'eco',
                label: 'Environmental'
            },
            'Environmental': {
                cls: 'badge-env',
                icon: 'eco',
                label: 'Environmental'
            },
            'Others': {
                cls: 'badge-others',
                icon: 'category',
                label: 'Others'
            },
        };
        const b = labels[category] || {
            cls: 'badge-pending',
            icon: 'help',
            label: category
        };
        return `<span class="badge ${b.cls}"><span class="material-symbols-outlined">${b.icon}</span>${Utils.esc(b.label)}</span>`;
    },

    // Placeholder image for broken/missing photos
    photoPlaceholder() {
        return `<div class="table-photo-placeholder"><span class="material-symbols-outlined">image</span></div>`;
    },

    // Show toast notification
    showToast(message, type = 'info', duration = 3000) {
        let container = document.querySelector('.toast-container');
        if (!container) {
            container = document.createElement('div');
            container.className = 'toast-container';
            document.body.appendChild(container);
        }
        const icons = {
            success: 'check_circle',
            error: 'error',
            info: 'info'
        };
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        // message is plain text (it often carries server/API messages).
        toast.innerHTML = `<span class="material-symbols-outlined" style="font-size:18px">${icons[type] || 'info'}</span>${Utils.esc(message)}`;
        container.appendChild(toast);
        setTimeout(() => {
            toast.style.animation = 'none';
            toast.style.opacity = '0';
            toast.style.transition = 'opacity 0.3s ease';
            setTimeout(() => toast.remove(), 300);
        }, duration);
    },

    // Debounce
    debounce(fn, delay = 300) {
        let t;
        return (...args) => {
            clearTimeout(t);
            t = setTimeout(() => fn(...args), delay);
        };
    },

    // Get URL param
    getParam(name) {
        return new URLSearchParams(window.location.search).get(name);
    },

    // Compose a citizen's home address from its separate parts
    // (street, purok, barangay, city, province), skipping blank fields.
    fullAddress(citizen) {
        if (!citizen) return '—';
        const parts = [citizen.street, citizen.purok, citizen.barangay, citizen.city, citizen.province]
            .map(p => (p || '').trim())
            .filter(Boolean);
        return parts.length ? parts.join(', ') : '—';
    },

    // ── Office report helpers ─────────────────────────────────────────
    // The API stores the canonical status 'Assigned to Office'; the office
    // pages show the short label 'Assigned'. apiStatusValue() is the exact
    // inverse, used when posting a status change back to the API.
    officeStatusLabel(status) {
        const s = String(status || '');
        return s === 'Assigned to Office' ? 'Assigned' : s;
    },

    apiStatusValue(label) {
        const s = String(label || '');
        return s === 'Assigned' ? 'Assigned to Office' : s;
    },

    // Format an API timestamp as e.g. 'May 21, 2026' / '9:20 AM'.
    shortDate(str) {
        if (!str) return '—';
        const d = new Date(str);
        if (isNaN(d)) return String(str);
        return d.toLocaleDateString('en-PH', { month: 'short', day: 'numeric', year: 'numeric' });
    },

    shortTime(str) {
        if (!str) return '';
        const d = new Date(str);
        if (isNaN(d)) return '';
        return d.toLocaleTimeString('en-PH', { hour: 'numeric', minute: '2-digit' });
    },

    // The date a report was handed to an office (its 'Assigned to Office'
    // activity), falling back to the submission date.
    assignedDate(r) {
        const acts = (r && (r.activityLog || r.activities)) || [];
        const a = acts.find(x => x && x.status === 'Assigned to Office');
        return this.shortDate((a && a.timestamp) || r.submittedAt || r.created_at);
    },

    // Flatten one report from GET /api/admin/citizen-reports into the shape
    // every office list page renders.
    officeReport(r) {
        r = r || {};
        const submittedAt = r.submittedAt || r.created_at || null;
        const resolvedAt = r.resolvedAt || r.resolved_at || null;
        return {
            id: r.id != null ? r.id : null,
            ref: r.referenceNumber || r.reference_number || (r.id != null ? String(r.id) : ''),
            issue: r.issue || r.concern || 'Report',
            category: r.category || '',
            barangay: r.barangay || '—',
            priority: r.priority || 'Medium',
            status: this.officeStatusLabel(r.status),
            rawStatus: r.status || '',
            date: this.shortDate(submittedAt),
            time: this.shortTime(submittedAt),
            dateAssigned: this.assignedDate(r),
            dateResolved: this.shortDate(resolvedAt),
            imageUrl: r.imageUrl || r.photo_url || null,
            assignedBy: r.assignedOffice || '',
            submittedAt: submittedAt,
            resolvedAt: resolvedAt,
        };
    },

    // Fetch every report assigned to the signed-in office. Falls back to the
    // caller's built-in sample rows when there is no backend or no token, so
    // the page still previews as a prototype.
    async fetchOfficeReports(sampleRows) {
        const sample = sampleRows || [];
        if (typeof Api === 'undefined' || !Api.token()) {
            return { reports: sample, live: false };
        }
        try {
            const json = await Api.get('/api/admin/citizen-reports', { limit: 500 });
            if (json && json.success) {
                const rows = (json.data && json.data.data) ? json.data.data : (json.data || []);
                return { reports: rows.map(r => Utils.officeReport(r)), live: true };
            }
        } catch (e) {
            console.warn('Falling back to sample office reports:', e);
        }
        return { reports: sample, live: false };
    },

    // Format relative time
    relativeTime(minutesAgo) {
        if (minutesAgo < 1) return 'just now';
        if (minutesAgo < 60) return `${minutesAgo} minutes ago`;
        if (minutesAgo < 120) return '1 hour ago';
        if (minutesAgo < 1440) return `${Math.floor(minutesAgo / 60)} hours ago`;
        return `${Math.floor(minutesAgo / 1440)} days ago`;
    },

    // Highlight search term
    // Returns HTML: both the text and the query are escaped first.
    highlight(text, query) {
        const safe = Utils.esc(text);
        if (!query) return safe;
        const q = Utils.esc(query);
        const re = new RegExp(`(${q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
        return safe.replace(re, '<mark style="background:#FEF9C3;border-radius:2px">$1</mark>');
    }
};

// ============================================================
// Shared Photo renderer - Real Unsplash images for demo
// ============================================================
const PHOTO_URLS = {
    'damaged-road': 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=400&h=300&fit=crop&q=80',
    'illegal-dumping': 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400&h=300&fit=crop&q=80',
    'damaged-sidewalk': 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=400&h=300&fit=crop&q=80',
    'blocked-drainage': 'https://images.unsplash.com/photo-1590845947670-c009801ffa74?w=400&h=300&fit=crop&q=80',
    'overgrown': 'https://images.unsplash.com/photo-1588392382834-a891154bca4d?w=400&h=300&fit=crop&q=80',
    'streetlight': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&h=300&fit=crop&q=80',
    'broken-bridge': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&q=80',
    'soil-erosion': 'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400&h=300&fit=crop&q=80',
    'road-sign': 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=400&h=300&fit=crop&q=80',
};

function getPhotoUrl(issue) {
    const key = (issue || '').toLowerCase().replace(/\s+/g, '-');
    const map = {
        'damaged-road': PHOTO_URLS['damaged-road'],
        'illegal-dumping': PHOTO_URLS['illegal-dumping'],
        'damaged-sidewalk': PHOTO_URLS['damaged-sidewalk'],
        'blocked-drainage': PHOTO_URLS['blocked-drainage'],
        'overgrown-vegetation': PHOTO_URLS['overgrown'],
        'broken-streetlight': PHOTO_URLS['streetlight'],
        'soil-erosion': PHOTO_URLS['soil-erosion'],
        'blocked-canal': PHOTO_URLS['blocked-drainage'],
        'road-sign-damage': PHOTO_URLS['road-sign'],
        'damaged-bridge': PHOTO_URLS['broken-bridge'],
    };
    return map[key] || PHOTO_URLS['damaged-road'];
}

// Full-size version for detail pages (larger images)
function getPhotoUrlLarge(issue) {
    const key = (issue || '').toLowerCase().replace(/\s+/g, '-');
    const map = {
        'damaged-road': 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800&h=500&fit=crop&q=85',
        'illegal-dumping': 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=800&h=500&fit=crop&q=85',
        'damaged-sidewalk': 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=800&h=500&fit=crop&q=85',
        'blocked-drainage': 'https://images.unsplash.com/photo-1590845947670-c009801ffa74?w=800&h=500&fit=crop&q=85',
        'overgrown-vegetation': 'https://images.unsplash.com/photo-1588392382834-a891154bca4d?w=800&h=500&fit=crop&q=85',
        'broken-streetlight': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&h=500&fit=crop&q=85',
        'soil-erosion': 'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=800&h=500&fit=crop&q=85',
        'blocked-canal': 'https://images.unsplash.com/photo-1590845947670-c009801ffa74?w=800&h=500&fit=crop&q=85',
        'road-sign-damage': 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=500&fit=crop&q=85',
        'damaged-bridge': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&h=500&fit=crop&q=85',
    };
    return map[key] || 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800&h=500&fit=crop&q=85';
}


// ============================================================
// CwModal — Loading / Success / Error modal system
// ============================================================
//
// Usage:
//   CwModal.loading('Saving changes...')   — show non-dismissible spinner
//   CwModal.success('Done!', 'Report validated successfully.')
//   CwModal.error('Failed', 'Could not reach the server.')
//   CwModal.hide()                         — close whatever is open
//
// Only one modal exists in the DOM at a time (singleton shell).
// ============================================================

const CwModal = (() => {
    const SHELL_ID = 'cwModalShell';

    // ── Ensure the shell exists ───────────────────────────────────────────
    function _ensureShell() {
        if (document.getElementById(SHELL_ID)) return;

        const shell = document.createElement('div');
        shell.id = SHELL_ID;
        shell.innerHTML = `
      <div class="cw-modal-backdrop" id="cwModalBackdrop"></div>
      <div class="cw-modal-wrap" id="cwModalWrap" role="dialog" aria-modal="true">
        <div class="cw-modal-box" id="cwModalBox">
          <div class="cw-modal-icon-wrap" id="cwModalIconWrap"></div>
          <div class="cw-modal-title" id="cwModalTitle"></div>
          <div class="cw-modal-message" id="cwModalMessage"></div>
          <div class="cw-modal-actions" id="cwModalActions"></div>
        </div>
      </div>`;
        document.body.appendChild(shell);

        // Backdrop click closes dismissible modals
        document.getElementById('cwModalBackdrop')
            .addEventListener('click', () => {
                if (document.getElementById(SHELL_ID).dataset.dismissible === 'true') {
                    CwModal.hide();
                }
            });
    }

    // ── Show helper ───────────────────────────────────────────────────────
    function _show({
        variant,
        title,
        message,
        actionLabel,
        onAction,
        dismissible = true
    }) {
        _ensureShell();
        const shell = document.getElementById(SHELL_ID);
        const iconWrap = document.getElementById('cwModalIconWrap');
        const titleEl = document.getElementById('cwModalTitle');
        const msgEl = document.getElementById('cwModalMessage');
        const actionsEl = document.getElementById('cwModalActions');
        const box = document.getElementById('cwModalBox');

        // Reset classes
        box.className = 'cw-modal-box';

        shell.dataset.dismissible = String(dismissible);

        // ── Variant config ────────────────────────────────────────────────
        const cfg = {
            loading: {
                iconHtml: `<div class="cw-modal-spinner"></div>`,
                boxClass: 'cw-modal-box--loading',
                showActions: false,
            },
            success: {
                iconHtml: `<span class="material-symbols-outlined cw-modal-icon cw-modal-icon--success">check_circle</span>`,
                boxClass: 'cw-modal-box--success',
                showActions: true,
            },
            error: {
                iconHtml: `<span class="material-symbols-outlined cw-modal-icon cw-modal-icon--error">error</span>`,
                boxClass: 'cw-modal-box--error',
                showActions: true,
            },
        } [variant] || cfg.error;

        box.classList.add(cfg.boxClass);
        iconWrap.innerHTML = cfg.iconHtml;
        titleEl.textContent = title || '';
        msgEl.textContent = message || '';
        titleEl.style.display = title ? '' : 'none';
        msgEl.style.display = message ? '' : 'none';

        // Actions
        actionsEl.innerHTML = '';
        if (cfg.showActions) {
            const btn = document.createElement('button');
            btn.className = 'cw-modal-btn';
            btn.textContent = actionLabel || 'OK';
            btn.classList.add(variant === 'success' ? 'cw-modal-btn--success' : 'cw-modal-btn--error');
            btn.addEventListener('click', () => {
                CwModal.hide();
                if (typeof onAction === 'function') onAction();
            });
            actionsEl.appendChild(btn);
        }

        // Animate in
        shell.classList.add('cw-modal--active');
        requestAnimationFrame(() => {
            requestAnimationFrame(() => box.classList.add('cw-modal-box--visible'));
        });
    }

    // ── Public API ────────────────────────────────────────────────────────
    return {
        loading(message = 'Please wait...') {
            _show({
                variant: 'loading',
                message,
                dismissible: false
            });
        },

        success(title, message, {
            actionLabel = 'OK',
            onAction
        } = {}) {
            _show({
                variant: 'success',
                title,
                message,
                actionLabel,
                onAction,
                dismissible: false
            });
        },

        error(title, message, {
            actionLabel = 'Close',
            onAction
        } = {}) {
            _show({
                variant: 'error',
                title,
                message,
                actionLabel,
                onAction,
                dismissible: true
            });
        },

        hide() {
            const shell = document.getElementById(SHELL_ID);
            if (!shell) return;
            const box = document.getElementById('cwModalBox');
            if (box) box.classList.remove('cw-modal-box--visible');
            setTimeout(() => shell.classList.remove('cw-modal--active'), 220);
        },
    };
})();

// ============================================================
// Skeleton helpers
// ============================================================
//
// Usage:
//   Skeleton.box(width, height, radius)       — returns HTML string
//   Skeleton.text(width)                      — slim text-line placeholder
//   Skeleton.row(cols)                        — table row of skeleton cells
//   Skeleton.tableRows(rowCount, colCount)    — full tbody placeholder
//   Skeleton.card()                           — stat-card placeholder
//   Skeleton.injectTableRows(tbodyId, rows, cols) — inject & auto-remove
//
// Skeletons remove themselves when real content is inserted via
// Skeleton.clear(tbodyId).
// ============================================================

const Skeleton = (() => {
    const box = (w = '100%', h = 14, r = 6) =>
        `<div class="sk-box" style="width:${typeof w === 'number' ? w + 'px' : w};height:${h}px;border-radius:${r}px"></div>`;

    const text = (w = '80%') => box(w, 13, 6);

    const cell = (w = '80%') =>
        `<td><div class="sk-cell">${box(w, 13)}</div></td>`;

    const row = (cols = 6) =>
        `<tr class="sk-row">${Array.from({ length: cols }, (_, i) =>
            cell(i === 0 ? '60%' : i === cols - 1 ? '40%' : '75%')
        ).join('')}</tr>`;

    const tableRows = (rowCount = 5, colCount = 6) =>
        Array.from({
            length: rowCount
        }, () => row(colCount)).join('');

    const card = () => `
    <div class="sk-card">
      ${box('40%', 12)} 
      <div style="margin-top:10px">${box('55%', 28, 4)}</div>
      <div style="margin-top:8px">${text('70%')}</div>
    </div>`;

    const injectTableRows = (tbodyId, rowCount = 5, colCount = 6) => {
        const tbody = document.getElementById(tbodyId);
        if (!tbody) return;
        tbody.innerHTML = tableRows(rowCount, colCount);
    };

    const clear = (tbodyId) => {
        const tbody = document.getElementById(tbodyId);
        if (tbody) {
            tbody.querySelectorAll('.sk-row').forEach(r => r.remove());
        }
    };

    return {
        box,
        text,
        cell,
        row,
        tableRows,
        card,
        injectTableRows,
        clear
    };
})();