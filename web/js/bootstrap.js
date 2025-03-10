// Bootstrap file for Flutter web initialization in Replit

// Direct init function
function bootstrapFlutter() {
  console.log('Starting Flutter bootstrap...');
  
  // Get loading indicator
  var loadingIndicator = document.getElementById('loading');
  
  // Create main Dart.js script
  var mainScript = document.createElement('script');
  mainScript.src = 'main.dart.js';
  mainScript.type = 'application/javascript';
  
  // Log success or failure
  mainScript.addEventListener('load', function() {
    console.log('Flutter app loaded successfully');
  });
  
  mainScript.addEventListener('error', function(e) {
    console.error('Failed to load Flutter application:', e);
    if (loadingIndicator) {
      loadingIndicator.innerHTML = '<p>Failed to load application. Please try again.</p>';
    }
  });
  
  // Add the script to the body
  document.body.appendChild(mainScript);
}

// Execute on load
window.addEventListener('load', bootstrapFlutter);