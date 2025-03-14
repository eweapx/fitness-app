// Temporary placeholder for Flutter web app
window.onload = function() {
  const loadingElement = document.querySelector('#loading');
  if (loadingElement) {
    // Remove loading indicator
    loadingElement.remove();
  }
  
  // Display a message in the body
  const container = document.createElement('div');
  container.style.width = '100%';
  container.style.height = '100%';
  container.style.display = 'flex';
  container.style.flexDirection = 'column';
  container.style.justifyContent = 'center';
  container.style.alignItems = 'center';
  container.style.textAlign = 'center';
  container.style.padding = '20px';
  container.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';
  
  const title = document.createElement('h1');
  title.textContent = 'Fuel Fitness';
  title.style.color = '#1976D2';
  title.style.marginBottom = '20px';
  
  const subtitle = document.createElement('h2');
  subtitle.textContent = 'Health & Fitness Tracker';
  subtitle.style.color = '#333';
  subtitle.style.marginBottom = '30px';
  
  const message = document.createElement('p');
  message.textContent = 'The Flutter web application is being configured. Check back soon!';
  message.style.fontSize = '18px';
  message.style.marginBottom = '20px';
  
  const features = document.createElement('div');
  features.style.display = 'flex';
  features.style.flexWrap = 'wrap';
  features.style.justifyContent = 'center';
  features.style.gap = '15px';
  features.style.maxWidth = '600px';
  
  const featureItems = [
    'Activity Tracking',
    'Nutrition Monitoring',
    'Sleep Analysis',
    'Meditation Timer',
    'Goal Setting',
    'Progress Reports'
  ];
  
  featureItems.forEach(item => {
    const feature = document.createElement('div');
    feature.textContent = item;
    feature.style.padding = '10px 15px';
    feature.style.backgroundColor = '#e3f2fd';
    feature.style.borderRadius = '20px';
    feature.style.color = '#0d47a1';
    features.appendChild(feature);
  });
  
  container.appendChild(title);
  container.appendChild(subtitle);
  container.appendChild(message);
  container.appendChild(features);
  
  document.body.appendChild(container);
};