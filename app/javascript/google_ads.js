// Google Ads GCLID Capture
// Automatically captures gclid from URL parameters and stores in session

document.addEventListener('DOMContentLoaded', function() {
  // Check if we're on the landing page where Google Ads traffic arrives
  const urlParams = new URLSearchParams(window.location.search);
  const gclid = urlParams.get('gclid');
  const utmSource = urlParams.get('utm_source');
  const utmCampaign = urlParams.get('utm_campaign');
  const utmMedium = urlParams.get('utm_medium');
  
  if (gclid) {
    console.log('Google Ads click detected:', {
      gclid: gclid,
      utm_source: utmSource,
      utm_campaign: utmCampaign,
      utm_medium: utmMedium
    });
    
    // Store Google Ads data in sessionStorage for callback creation
    sessionStorage.setItem('google_ads_data', JSON.stringify({
      gclid: gclid,
      utm_source: utmSource,
      utm_campaign: utmCampaign,
      utm_medium: utmMedium,
      landing_page: window.location.href,
      timestamp: new Date().toISOString()
    }));
    
    // Send to server to store in session
    fetch('/capture_google_ads', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        gclid: gclid,
        utm_source: utmSource,
        utm_campaign: utmCampaign,
        utm_medium: utmMedium
      })
    }).catch(error => {
      console.log('Google Ads data stored locally only:', error);
    });
  }
  
  // When creating callbacks, attach Google Ads data if available
  const callbackForms = document.querySelectorAll('.callback-form');
  callbackForms.forEach(form => {
    form.addEventListener('submit', function() {
      const googleAdsData = sessionStorage.getItem('google_ads_data');
      if (googleAdsData) {
        const data = JSON.parse(googleAdsData);
        
        // Add hidden fields to form if they don't exist
        if (!form.querySelector('[name="google_ads_gclid"]') && data.gclid) {
          const gclidInput = document.createElement('input');
          gclidInput.type = 'hidden';
          gclidInput.name = 'google_ads_gclid';
          gclidInput.value = data.gclid;
          form.appendChild(gclidInput);
        }
        
        if (!form.querySelector('[name="google_ads_utm_source"]') && data.utm_source) {
          const sourceInput = document.createElement('input');
          sourceInput.type = 'hidden';
          sourceInput.name = 'google_ads_utm_source';
          sourceInput.value = data.utm_source;
          form.appendChild(sourceInput);
        }
        
        if (!form.querySelector('[name="google_ads_utm_campaign"]') && data.utm_campaign) {
          const campaignInput = document.createElement('input');
          campaignInput.type = 'hidden';
          campaignInput.name = 'google_ads_utm_campaign';
          campaignInput.value = data.utm_campaign;
          form.appendChild(campaignInput);
        }
      }
    });
  });
  
  // Display Google Ads attribution in admin areas
  const googleAdsData = sessionStorage.getItem('google_ads_data');
  if (googleAdsData) {
    const data = JSON.parse(googleAdsData);
    const debugElement = document.querySelector('#google-ads-debug');
    if (debugElement) {
      debugElement.innerHTML = `
        <div class="google-ads-attribution">
          <h4>Google Ads Attribution</h4>
          <p><strong>GCLID:</strong> ${data.gclid || 'N/A'}</p>
          <p><strong>Campaign:</strong> ${data.utm_campaign || 'N/A'}</p>
          <p><strong>Source:</strong> ${data.utm_source || 'N/A'}</p>
          <p><strong>Landing:</strong> ${data.landing_page || 'N/A'}</p>
          <p><strong>Time:</strong> ${new Date(data.timestamp).toLocaleString()}</p>
        </div>
      `;
    }
  }
});

// Helper function to get current Google Ads data
window.getGoogleAdsData = function() {
  const stored = sessionStorage.getItem('google_ads_data');
  return stored ? JSON.parse(stored) : null;
};

// Helper function to clear Google Ads data (useful after successful conversion)
window.clearGoogleAdsData = function() {
  sessionStorage.removeItem('google_ads_data');
};