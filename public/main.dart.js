// Flutter Web App Entry Point - Enhanced version
// This provides an actual UI while Flutter builds

// This creates a mock Flutter engine initializer to make the Flutter loader happy
var didCreateEngineInitializerResolve = null;

// Create a proper engineInitializer object with methods that Flutter's loader expects
window._flutter = window._flutter || {};
window._flutter.loader = window._flutter.loader || {};
window._flutter.loader.didCreateEngineInitializer = function(engineInitializer) {
  if (typeof didCreateEngineInitializerResolve === "function") {
    didCreateEngineInitializerResolve(engineInitializer);
  }
};

// Helper function to create DOM elements
function createElement(tag, options = {}) {
  const element = document.createElement(tag);
  if (options.className) element.className = options.className;
  if (options.id) element.id = options.id;
  if (options.text) element.textContent = options.text;
  if (options.html) element.innerHTML = options.html;
  if (options.styles) {
    Object.keys(options.styles).forEach(key => {
      element.style[key] = options.styles[key];
    });
  }
  if (options.attributes) {
    Object.keys(options.attributes).forEach(key => {
      element.setAttribute(key, options.attributes[key]);
    });
  }
  if (options.parent) options.parent.appendChild(element);
  
  return element;
}

// The main entry point for the application
function main() {
  // Create a more substantial UI while Flutter builds
  renderHealthFitnessApp();
  
  // Mock Flutter engine
  const engineInitializer = {
    initializeEngine: function() {
      console.log("Flutter engine initialized");
      return Promise.resolve({
        runApp: function() {
          console.log("Flutter app running");
          renderHealthFitnessApp();
        }
      });
    }
  };
  
  // Resolve the engine initializer promise
  if (window._flutter && window._flutter.loader) {
    window._flutter.loader.didCreateEngineInitializer(engineInitializer);
  }
}

// Renders our Health & Fitness tracking application UI
function renderHealthFitnessApp() {
  // Remove any existing loading indicator
  const loadingElement = document.querySelector('#loading');
  if (loadingElement) {
    loadingElement.remove();
  }
  
  // Create the main container for our app
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
  container.style.backgroundColor = '#f5f5f5';
  
  // App header with logo
  const header = document.createElement('div');
  header.style.marginBottom = '40px';
  
  const title = document.createElement('h1');
  title.textContent = 'Fuel Fitness';
  title.style.color = '#1976D2';
  title.style.fontSize = '36px';
  title.style.marginBottom = '10px';
  
  const subtitle = document.createElement('h2');
  subtitle.textContent = 'Health & Fitness Tracker';
  subtitle.style.color = '#333';
  subtitle.style.fontSize = '20px';
  subtitle.style.fontWeight = 'normal';
  
  header.appendChild(title);
  header.appendChild(subtitle);
  
  // Card container for features
  const cardContainer = document.createElement('div');
  cardContainer.style.display = 'flex';
  cardContainer.style.flexWrap = 'wrap';
  cardContainer.style.justifyContent = 'center';
  cardContainer.style.gap = '20px';
  cardContainer.style.maxWidth = '800px';
  cardContainer.style.marginBottom = '30px';
  
  // Feature cards with icons
  const features = [
    { name: 'Activity Tracking', icon: '🏃‍♂️', color: '#e3f2fd' },
    { name: 'Nutrition Monitoring', icon: '🥗', color: '#e8f5e9' },
    { name: 'Sleep Analysis', icon: '😴', color: '#ede7f6' },
    { name: 'Meditation Timer', icon: '🧘‍♀️', color: '#fff8e1' },
    { name: 'Goal Setting', icon: '🎯', color: '#fce4ec' },
    { name: 'Progress Reports', icon: '📊', color: '#e0f7fa' }
  ];
  
  features.forEach(feature => {
    const card = document.createElement('div');
    card.style.padding = '25px';
    card.style.backgroundColor = feature.color;
    card.style.borderRadius = '12px';
    card.style.boxShadow = '0 4px 6px rgba(0,0,0,0.1)';
    card.style.width = '200px';
    card.style.textAlign = 'center';
    
    const icon = document.createElement('div');
    icon.textContent = feature.icon;
    icon.style.fontSize = '40px';
    icon.style.marginBottom = '15px';
    
    const name = document.createElement('div');
    name.textContent = feature.name;
    name.style.fontWeight = 'bold';
    name.style.fontSize = '16px';
    
    card.appendChild(icon);
    card.appendChild(name);
    cardContainer.appendChild(card);
  });
  
  // Status message
  const message = document.createElement('p');
  message.textContent = 'Flutter web application is in development. This is a preview of the upcoming features.';
  message.style.fontSize = '16px';
  message.style.marginTop = '20px';
  message.style.opacity = '0.7';
  
  // Navigation bar
  const navbar = document.createElement('div');
  navbar.style.position = 'fixed';
  navbar.style.bottom = '0';
  navbar.style.left = '0';
  navbar.style.right = '0';
  navbar.style.backgroundColor = '#1976D2';
  navbar.style.display = 'flex';
  navbar.style.justifyContent = 'space-around';
  navbar.style.padding = '15px 0';
  navbar.style.boxShadow = '0 -2px 10px rgba(0,0,0,0.1)';
  
  const navItems = ['Home', 'Activities', 'Nutrition', 'Progress', 'Profile'];
  
  navItems.forEach(item => {
    const navItem = document.createElement('div');
    navItem.textContent = item;
    navItem.style.color = 'white';
    navItem.style.fontWeight = item === 'Home' ? 'bold' : 'normal';
    navItem.style.cursor = 'pointer';
    navbar.appendChild(navItem);
  });
  
  // Assemble the app
  container.appendChild(header);
  container.appendChild(cardContainer);
  container.appendChild(message);
  document.body.appendChild(container);
  document.body.appendChild(navbar);
}

// Start the application
main();