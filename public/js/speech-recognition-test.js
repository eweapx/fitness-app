/**
 * Speech Recognition Test Script
 * This file helps debug and test voice recognition in isolation.
 */

// Create a simple speech recognition test
function testSpeechRecognition() {
  console.log('Testing speech recognition...');
  logTestResult('Starting speech recognition test...');
  
  // Log information about the browser
  const userAgent = navigator.userAgent;
  logTestResult(`Browser: ${userAgent}`);
  
  // Check browser support
  if (!('SpeechRecognition' in window) && !('webkitSpeechRecognition' in window)) {
    logTestResult('❌ Speech recognition is NOT supported in this browser');
    return;
  }
  
  logTestResult('✅ Speech recognition IS supported in this browser');
  
  // Check for global speech recognizer instance
  if (window.speechRecognizer) {
    logTestResult(`Global speechRecognizer exists: ${typeof window.speechRecognizer}`);
    if (window.speechRecognizer.recognition) {
      logTestResult('Global speechRecognizer has recognition object');
    } else {
      logTestResult('Global speechRecognizer exists but has no recognition object');
    }
  } else {
    logTestResult('No global speechRecognizer found');
  }
  
  // Check for permissions API
  if (navigator.permissions && navigator.permissions.query) {
    navigator.permissions.query({ name: 'microphone' })
      .then(permissionStatus => {
        logTestResult(`Microphone permission status: ${permissionStatus.state}`);
        
        permissionStatus.onchange = () => {
          logTestResult(`Microphone permission changed to: ${permissionStatus.state}`);
        };
      })
      .catch(error => {
        logTestResult(`Error checking microphone permission: ${error.message}`);
      });
  } else {
    logTestResult('Permissions API is not available in this browser');
  }
  
  // Create fresh test recognition object
  try {
    logTestResult('Creating new SpeechRecognition instance for testing...');
    
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    const recognition = new SpeechRecognition();
    
    // Configure recognition
    recognition.continuous = false;
    recognition.interimResults = false;
    recognition.lang = 'en-US';
    
    // Set up detailed event handlers for thorough logging
    recognition.onstart = (event) => {
      logTestResult('🎤 Recognition started, please speak now');
      console.log('Recognition start event:', event);
    };
    
    recognition.onresult = (event) => {
      console.log('Recognition result event:', event);
      
      try {
        const result = event.results[0][0];
        const transcript = result.transcript;
        const confidence = result.confidence;
        
        logTestResult(`🗣️ Heard: "${transcript}" (Confidence: ${confidence.toFixed(2)})`);
        
        // Try to process with global instance if available
        if (window.speechRecognizer && typeof window.speechRecognizer.processCommand === 'function') {
          logTestResult('Attempting to process command with global speechRecognizer...');
          try {
            window.speechRecognizer.processCommand(transcript);
            logTestResult('✅ Command processing succeeded');
          } catch (processingError) {
            logTestResult(`❌ Error in command processing: ${processingError.message}`);
            console.error('Command processing error:', processingError);
          }
        } else {
          logTestResult('Note: Global speechRecognizer not available for command processing');
        }
      } catch (resultError) {
        logTestResult(`❌ Error processing recognition result: ${resultError.message}`);
        console.error('Result processing error:', resultError);
      }
    };
    
    recognition.onerror = (event) => {
      console.error('Recognition error event:', event);
      logTestResult(`❌ Error in recognition: ${event.error}`);
      
      // Provide more detailed error information
      switch (event.error) {
        case 'no-speech':
          logTestResult('No speech was detected. Try speaking louder or adjusting microphone.');
          break;
        case 'aborted':
          logTestResult('Recognition was aborted, possibly by another recognition starting.');
          break;
        case 'audio-capture':
          logTestResult('No microphone was found or microphone failed to capture audio.');
          break;
        case 'network':
          logTestResult('Network error occurred. Check your internet connection.');
          break;
        case 'not-allowed':
          logTestResult('Microphone permission was denied. Check browser permissions.');
          break;
        case 'service-not-allowed':
          logTestResult('Speech recognition service not allowed by the browser.');
          break;
        case 'bad-grammar':
          logTestResult('Grammar error in speech recognition.');
          break;
        default:
          logTestResult(`Error details: ${JSON.stringify(event)}`);
      }
    };
    
    recognition.onend = (event) => {
      console.log('Recognition end event:', event);
      logTestResult('🛑 Recognition ended');
      
      // Enable test button again
      document.getElementById('test-recognition-btn').disabled = false;
    };
    
    // Store recognition object so the stopTest function can access it
    window.testRecognition = recognition;
    
    // Log state before starting
    logTestResult('Starting recognition now...');
    
    // Start recognition with error handling
    try {
      recognition.start();
      logTestResult('Recognition.start() called successfully');
    } catch (startError) {
      logTestResult(`❌ Error starting recognition: ${startError.message}`);
      console.error('Start error:', startError);
      
      // Try recovery by creating a new instance after a delay
      if (startError.name === 'InvalidStateError') {
        logTestResult('Attempting to recover from InvalidStateError...');
        setTimeout(() => {
          logTestResult('Creating new recognition instance after error...');
          window.testRecognition = new SpeechRecognition();
          // Configure basic properties again
          window.testRecognition.continuous = false;
          window.testRecognition.interimResults = false;
          try {
            window.testRecognition.start();
            logTestResult('✅ Recovery succeeded, recognition started');
          } catch (recoveryError) {
            logTestResult(`❌ Recovery failed: ${recoveryError.message}`);
          }
        }, 200);
      }
    }
    
    // Disable test button while listening
    document.getElementById('test-recognition-btn').disabled = true;
    
  } catch (error) {
    logTestResult(`❌ Error creating speech recognition: ${error.message}`);
    console.error('Creation error:', error);
  }
}

function stopTest() {
  logTestResult('Stopping test...');
  
  if (window.testRecognition) {
    try {
      window.testRecognition.stop();
      logTestResult('✅ Recognition stopped manually');
    } catch (error) {
      logTestResult(`❌ Error stopping recognition: ${error.message}`);
      console.error('Stop error:', error);
      
      // Try to abort if stop fails
      if (error.name === 'InvalidStateError') {
        try {
          logTestResult('Trying to abort instead...');
          window.testRecognition.abort();
          logTestResult('✅ Recognition aborted successfully');
        } catch (abortError) {
          logTestResult(`❌ Abort also failed: ${abortError.message}`);
        }
      }
    }
    
    // Clean up event handlers
    try {
      window.testRecognition.onstart = null;
      window.testRecognition.onresult = null;
      window.testRecognition.onerror = null;
      window.testRecognition.onend = null;
      logTestResult('Event handlers cleaned up');
    } catch (cleanupError) {
      logTestResult(`Error during cleanup: ${cleanupError.message}`);
    }
    
    // Enable test button again
    document.getElementById('test-recognition-btn').disabled = false;
  } else {
    logTestResult('No active recognition to stop');
  }
}

function logTestResult(message) {
  const logContainer = document.getElementById('recognition-test-log');
  if (logContainer) {
    const logEntry = document.createElement('div');
    logEntry.className = 'test-log-entry';
    
    // Format timestamp
    const now = new Date();
    const timeString = now.toTimeString().split(' ')[0];
    const timestampSpan = document.createElement('span');
    timestampSpan.className = 'log-timestamp';
    timestampSpan.textContent = `[${timeString}] `;
    
    logEntry.appendChild(timestampSpan);
    logEntry.appendChild(document.createTextNode(message));
    
    logContainer.appendChild(logEntry);
    logContainer.scrollTop = logContainer.scrollHeight; // Auto-scroll to bottom
  } else {
    console.log(message);
  }
}

// Set up event handlers once DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
  const testButton = document.getElementById('test-recognition-btn');
  if (testButton) {
    testButton.addEventListener('click', testSpeechRecognition);
  }
  
  const stopButton = document.getElementById('stop-recognition-btn');
  if (stopButton) {
    stopButton.addEventListener('click', stopTest);
  }
  
  const clearLogButton = document.getElementById('clear-log-btn');
  if (clearLogButton) {
    clearLogButton.addEventListener('click', function() {
      const logContainer = document.getElementById('recognition-test-log');
      if (logContainer) {
        logContainer.innerHTML = '';
      }
    });
  }
});