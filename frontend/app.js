const API_BASE = "http://localhost:8000/api/v1";

// --- Navigation ---
function showSection(sectionId) {
    document.querySelectorAll('main section').forEach(s => s.classList.remove('active-section'));
    document.querySelectorAll('.nav-links li').forEach(l => l.classList.remove('active'));
    
    document.getElementById(`${sectionId}-section`).classList.add('active-section');
    event.currentTarget.classList.add('active');

    if (sectionId === 'dashboard') loadLots();
}

// --- Dashboard Logic ---
async function loadLots() {
    showLoader(true);
    try {
        const response = await fetch(`${API_BASE}/audit/query/status/COLLECTE`);
        const lots = await response.json();
        
        const tbody = document.getElementById('lots-table-body');
        tbody.innerHTML = '';
        
        lots.forEach(lot => {
            const row = `
                <tr>
                    <td><strong>${lot.lotHash}</strong></td>
                    <td>${lot.espece}</td>
                    <td>${lot.poidsKg}</td>
                    <td><span class="status-pill status-${lot.statut}">${lot.statut}</span></td>
                    <td>
                        <button onclick="viewLotDetails('${lot.lotHash}')" class="btn-small">Détails</button>
                    </td>
                </tr>
            `;
            tbody.insertAdjacentHTML('beforeend', row);
        });

        document.getElementById('stat-total').innerText = lots.length;
        // Simulating other stats for demo
        document.getElementById('stat-transit').innerText = Math.floor(lots.length * 0.3);
        document.getElementById('stat-cert').innerText = Math.floor(lots.length * 0.5);

    } catch (error) {
        console.error("Error loading lots:", error);
    } finally {
        showLoader(false);
    }
}

// --- Create Lot Logic ---
const form = document.getElementById('create-lot-form');
form.addEventListener('submit', async (e) => {
    e.preventDefault();
    showLoader(true);

    const formData = new FormData();
    formData.append('lot_hash', document.getElementById('lot_hash').value);
    formData.append('farmer_id', document.getElementById('farmer_id').value);
    formData.append('latitude', document.getElementById('latitude').value);
    formData.append('longitude', document.getElementById('longitude').value);
    formData.append('poids_kg', document.getElementById('poids_kg').value);
    formData.append('espece', document.getElementById('espece').value);
    formData.append('date_collecte', new Date().toISOString());
    formData.append('file', document.getElementById('image-file').files[0]);

    try {
        const response = await fetch(`${API_BASE}/lots/`, {
            method: 'POST',
            body: formData,
            headers: {
                'X-Org-Name': 'producteurs',
                'X-User-ID': 'Admin'
            }
        });

        const result = await response.json();
        if (result.success) {
            alert("Lot gravé avec succès sur la Blockchain !");
            form.reset();
            showSection('dashboard');
        } else {
            alert("Erreur: " + result.error);
        }
    } catch (error) {
        alert("Erreur de connexion au serveur.");
    } finally {
        showLoader(false);
    }
});

// --- Verification Logic ---
async function verifyLot() {
    const hash = document.getElementById('search-hash').value;
    if (!hash) return;

    showLoader(true);
    try {
        const response = await fetch(`${API_BASE}/audit/verify/${hash}`);
        const data = await response.json();
        
        const resultContainer = document.getElementById('verify-result');
        resultContainer.style.display = 'block';
        
        let journeyHtml = data.journey.map(step => `
            <div class="journey-step">
                <div class="step-icon">●</div>
                <div class="step-content">
                    <h4>${step.step}</h4>
                    <p>${new Date(step.date * 1000).toLocaleString()}</p>
                    <small>TX: ${step.txId}</small>
                </div>
            </div>
        `).join('');

        resultContainer.innerHTML = `
            <div class="verify-card">
                <div class="verify-header">
                    <h3>Lot: ${data.lot_id}</h3>
                    <span class="verified-badge"><i class="fas fa-check-circle"></i> Vérifié Blockchain</span>
                </div>
                <div class="verify-body">
                    <div class="info">
                        <p><strong>Produit:</strong> ${data.product}</p>
                        <p><strong>Espèce:</strong> ${data.harvest_info.species}</p>
                        <p><strong>Poids:</strong> ${data.harvest_info.weight} kg</p>
                    </div>
                    ${data.origin_photo ? `<img src="http://localhost:8000${data.origin_photo}" class="farm-photo">` : ''}
                </div>
                <h4>Parcours du produit :</h4>
                <div class="journey-timeline">
                    ${journeyHtml}
                </div>
            </div>
        `;
    } catch (error) {
        alert("Lot introuvable ou erreur de traçabilité.");
    } finally {
        showLoader(false);
    }
}

// --- Helpers ---
function showLoader(show) {
    document.getElementById('loader').style.display = show ? 'flex' : 'none';
}

// Image Preview
document.getElementById('drop-area').addEventListener('click', () => document.getElementById('image-file').click());
document.getElementById('image-file').addEventListener('change', function() {
    if (this.files && this.files[0]) {
        const reader = new FileReader();
        reader.onload = (e) => {
            const preview = document.getElementById('preview');
            preview.src = e.target.result;
            preview.style.display = 'block';
        }
        reader.readAsDataURL(this.files[0]);
    }
});

// --- Actor Registration Logic ---
const actorForm = document.getElementById('register-actor-form');
actorForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    showLoader(true);

    const payload = {
        actorIdHash: document.getElementById('actor_id').value,
        orgName: document.getElementById('actor_org').value,
        typeActeur: document.getElementById('actor_type').value,
        clePublique: document.getElementById('actor_key').value || "NO_KEY"
    };

    try {
        const response = await fetch(`${API_BASE}/actors/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const result = await response.json();
        if (result.success) {
            document.getElementById('register-success').style.display = 'block';
            document.getElementById('register-details').innerText = `ID: ${result.ca_details.userId} | Secret: ${result.ca_details.secret}`;
            actorForm.reset();
        } else {
            alert("Erreur: " + result.detail);
        }
    } catch (error) {
        alert("Erreur de connexion lors de l'enregistrement.");
    } finally {
        showLoader(false);
    }
});

// Initial load
loadLots();

