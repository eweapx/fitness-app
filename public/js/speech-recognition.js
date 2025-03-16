/**
 * Speech Recognition functionality for Health & Fitness Tracker
 * Allows users to log activities, nutrition, sleep, and other data using voice commands
 */

// Speech Recognition class that handles all voice command functionality
class SpeechRecognizer {
  constructor() {
    // Check if browser supports speech recognition
    this.recognition = null;
    this.isListening = false;
    this.transcript = '';
    this.confidence = 0;
    this.voiceCommandsEnabled = false;
    
    // Tracking for results state
    this.expectingResults = false;
    this.resultReceived = false;
    
    // Command handlers for different types of data
    // Explicitly bind all handlers to this instance to preserve context
    this.commandHandlers = {
      'activity': this.handleActivityCommand.bind(this),
      'workout': this.handleActivityCommand.bind(this), // Alias for activity
      'exercise': this.handleActivityCommand.bind(this), // Alias for activity
      'nutrition': this.handleNutritionCommand.bind(this),
      'meal': this.handleNutritionCommand.bind(this), // Alias for nutrition
      'food': this.handleNutritionCommand.bind(this), // Alias for nutrition
      'sleep': this.handleSleepCommand.bind(this),
      'habit': this.handleHabitCommand.bind(this),
      'steps': this.handleStepsCommand.bind(this)
    };
    
    this.initializeSpeechRecognition();
  }

  /**
   * Initialize the speech recognition API
   */
  initializeSpeechRecognition() {
    console.log('Initializing speech recognition from speech-recognition.js');

    // Check if we already have a global instance to avoid duplicates
    if (window.speechRecognizer && window.speechRecognizer !== this) {
      console.log('Speech recognition already initialized by app.js');
      // Use the existing instance's recognition object if available
      if (window.speechRecognizer.recognition) {
        this.recognition = window.speechRecognizer.recognition;
        this.voiceCommandsEnabled = window.speechRecognizer.voiceCommandsEnabled;
        return;
      }
    }

    // Check for browser support
    if ('SpeechRecognition' in window || 'webkitSpeechRecognition' in window) {
      try {
        // Create speech recognition instance
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        this.recognition = new SpeechRecognition();
        
        // Configure recognition
        this.recognition.continuous = false;
        this.recognition.interimResults = false;
        this.recognition.lang = 'en-US';
        
        // Set up event handlers with explicit binding to maintain context
        this.recognition.onstart = this.handleRecognitionStart.bind(this);
        this.recognition.onresult = this.handleRecognitionResult.bind(this);
        this.recognition.onerror = this.handleRecognitionError.bind(this);
        this.recognition.onend = this.handleRecognitionEnd.bind(this);
        
        this.voiceCommandsEnabled = true;
        console.log('Speech recognition initialized successfully');
      } catch (error) {
        console.error('Error initializing speech recognition:', error);
        this.voiceCommandsEnabled = false;
      }
    } else {
      console.error('Speech recognition not supported in this browser');
      this.voiceCommandsEnabled = false;
    }
    
    // Register as the global instance if none exists
    if (!window.speechRecognizer) {
      window.speechRecognizer = this;
    }
  }

  /**
   * Toggle listening state
   */
  toggleListening() {
    if (!this.voiceCommandsEnabled) {
      showToast('Speech recognition is not supported in your browser', 'error');
      return;
    }
    
    // Check if UI and internal state are in sync
    const micButton = document.getElementById('voice-command-toggle');
    const uiListening = micButton ? micButton.classList.contains('listening') : false;
    
    // If UI and internal state don't match, force reset for consistency
    if (this.isListening !== uiListening) {
      console.warn('Speech recognition state mismatch detected. Resetting...');
      this.resetRecognitionState();
      this.isListening = false;
      this.updateMicrophoneButton(false);
    }
    
    // Now toggle state safely
    if (this.isListening) {
      this.stopListening();
    } else {
      this.startListening();
    }
  }
  
  /**
   * Reset the recognition state to handle InvalidStateError
   * This creates a fresh instance of the recognition object
   */
  resetRecognitionState() {
    try {
      console.log('Resetting speech recognition state');
      
      // Only try to stop if we think we're listening
      if (this.isListening && this.recognition) {
        try {
          this.recognition.stop();
        } catch (e) {
          console.warn('Could not stop existing recognition:', e);
        }
      }
      
      // Clean up existing recognition object
      if (this.recognition) {
        this.recognition.onstart = null;
        this.recognition.onresult = null;
        this.recognition.onerror = null;
        this.recognition.onend = null;
        
        try {
          this.recognition.abort();
        } catch (e) {
          console.warn('Could not abort recognition:', e);
        }
      }
      
      // Create a fresh recognition instance
      setTimeout(() => {
        this.initializeSpeechRecognition();
      }, 100);
      
    } catch (e) {
      console.error('Error resetting recognition state:', e);
    }
  }

  /**
   * Start listening for voice commands
   */
  startListening() {
    if (!this.voiceCommandsEnabled) return;
    
    // Check if browser supports permissions API
    if (navigator.permissions && navigator.permissions.query) {
      navigator.permissions.query({ name: 'microphone' })
        .then(permissionStatus => {
          if (permissionStatus.state === 'granted') {
            this.startRecognition();
          } else if (permissionStatus.state === 'prompt') {
            // Will trigger the permission prompt
            this.startRecognition();
          } else if (permissionStatus.state === 'denied') {
            console.error('Microphone permission denied');
            showToast('Microphone access denied. Please enable it in your browser settings.', 'error');
            this.updateMicrophoneButton(false);
          }
          
          // Listen for changes to permission state
          permissionStatus.onchange = () => {
            if (permissionStatus.state === 'granted') {
              showToast('Microphone access granted', 'success');
            }
          };
        })
        .catch(error => {
          // Fallback if permissions API fails
          console.warn('Permission API error:', error);
          this.startRecognition();
        });
    } else {
      // Older browsers without permissions API
      this.startRecognition();
    }
  }
  
  /**
   * Start the actual recognition process
   * (separated to avoid code duplication)
   */
  startRecognition() {
    try {
      // Check if button state and internal state match
      const micButton = document.getElementById('voice-command-toggle');
      const uiListening = micButton ? micButton.classList.contains('listening') : false;
      
      if (uiListening !== this.isListening) {
        console.warn('State mismatch before starting recognition. Resetting...');
        this.resetRecognitionState();
        this.isListening = false;
        this.updateMicrophoneButton(false);
      }
      
      // Only start if definitely not already listening
      if (!this.isListening) {
        console.log('Starting speech recognition');
        
        // Double check recognition object exists and is in correct state
        if (!this.recognition) {
          this.initializeSpeechRecognition();
        }
        
        // Start recognition with a delay to ensure proper initialization
        setTimeout(() => {
          try {
            // Reset result tracking flags before starting
            this.expectingResults = true;
            this.resultReceived = false;
            
            // Start recognition
            this.recognition.start();
            this.updateMicrophoneButton(true);
            console.log('Speech recognition started successfully');
          } catch (delayedError) {
            console.error('Error starting speech recognition after delay:', delayedError);
            this.handleStartError(delayedError);
            
            // Reset flags on error
            this.expectingResults = false;
            this.resultReceived = false;
          }
        }, 50);
      } else {
        console.warn('Already listening, not starting again');
      }
    } catch (error) {
      console.error('Error starting speech recognition:', error);
      this.handleStartError(error);
    }
  }
  
  /**
   * Handle errors when starting speech recognition
   * @param {Error} error - The error that occurred
   */
  handleStartError(error) {
    this.updateMicrophoneButton(false);
    
    // Provide more specific error messages
    if (error.name === 'NotAllowedError') {
      showToast('Microphone access denied. Please allow access in your browser settings.', 'error');
    } else if (error.name === 'InvalidStateError') {
      console.warn('InvalidStateError detected. Creating new recognition instance.');
      // Call the more robust reset function
      this.resetRecognitionState();
      
      // Try again after a short delay
      setTimeout(() => {
        showToast('Speech recognition restarted. Please try again.', 'info');
      }, 300);
    } else {
      showToast('Could not start speech recognition: ' + (error.message || 'Unknown error'), 'error');
    }
  }

  /**
   * Stop listening for voice commands
   */
  stopListening() {
    if (!this.voiceCommandsEnabled) return;
    
    try {
      // Check for state mismatch before stopping
      const micButton = document.getElementById('voice-command-toggle');
      const uiListening = micButton ? micButton.classList.contains('listening') : false;
      
      if (uiListening !== this.isListening) {
        console.warn('State mismatch when stopping recognition. Fixing UI state.');
        // If UI thinks we're listening but we're not, just update UI
        if (uiListening && !this.isListening) {
          this.updateMicrophoneButton(false);
          return;
        }
      }
      
      // Only stop if we think we're currently listening
      if (this.isListening) {
        console.log('Stopping speech recognition');
        try {
          this.recognition.stop();
        } catch (innerError) {
          console.error('Error during recognition stop:', innerError);
          
          // If we got an InvalidStateError, the recognition was already stopped
          // We just need to ensure our state is consistent
          if (innerError.name === 'InvalidStateError') {
            console.warn('Recognition was already stopped. Fixing state.');
          }
          
          // Reset internal state if we hit errors
          this.resetRecognitionState();
        } finally {
          // Always update the UI to stopped state
          this.isListening = false;
          this.updateMicrophoneButton(false);
        }
      } else {
        console.warn('Not listening, no need to stop');
      }
    } catch (error) {
      console.error('Error in stopListening:', error);
      // Always make sure UI is in non-listening state if we encounter errors
      this.isListening = false;
      this.updateMicrophoneButton(false);
    }
  }

  /**
   * Handle recognition start event
   */
  handleRecognitionStart() {
    this.isListening = true;
    this.transcript = '';
    this.confidence = 0;
    this.updateMicrophoneButton(true);
    showToast('Listening...', 'info');
  }

  /**
   * Handle recognition result event
   * @param {SpeechRecognitionEvent} event - Speech recognition result event
   */
  handleRecognitionResult(event) {
    const result = event.results[0][0];
    this.transcript = result.transcript;
    this.confidence = result.confidence;
    
    // Mark that we received results successfully
    this.resultReceived = true;
    
    console.log(`Recognized: "${this.transcript}" (Confidence: ${this.confidence.toFixed(2)})`);
    
    // Process the command
    this.processCommand(this.transcript);
  }

  /**
   * Handle recognition error event
   * @param {SpeechRecognitionError} event - Speech recognition error event
   */
  handleRecognitionError(event) {
    console.error('Speech recognition error:', event.error);
    
    let errorMessage = 'Speech recognition error';
    let needsReset = false;
    
    switch (event.error) {
      case 'no-speech':
        errorMessage = 'No speech detected. Please try again.';
        break;
      case 'aborted':
        errorMessage = 'Recognition aborted.';
        needsReset = true;
        break;
      case 'audio-capture':
        errorMessage = 'Could not capture audio. Please check your microphone.';
        needsReset = true;
        break;
      case 'network':
        errorMessage = 'Network error occurred. Please check your connection.';
        needsReset = true;
        break;
      case 'not-allowed':
        errorMessage = 'Microphone access denied. Please check browser permissions.';
        needsReset = true;
        break;
      case 'service-not-allowed':
        errorMessage = 'Speech recognition service not allowed.';
        needsReset = true;
        break;
      case 'bad-grammar':
        errorMessage = 'Speech recognition grammar issue.';
        needsReset = true;
        break;
      case 'language-not-supported':
        errorMessage = 'Language not supported for speech recognition.';
        needsReset = true;
        break;
    }
    
    // Update internal state and UI
    this.isListening = false;
    this.updateMicrophoneButton(false);
    
    // Show error message
    showToast(errorMessage, 'error');
    
    // If needed, reset the recognition state after error
    if (needsReset) {
      setTimeout(() => {
        this.resetRecognitionState();
      }, 500);
    }
  }

  /**
   * Handle recognition end event
   */
  handleRecognitionEnd() {
    console.log('Recognition ended');
    
    // Check if we were expecting it to end
    if (this.isListening) {
      console.log('Recognition ended but we were still listening - possible abnormal termination');
    }
    
    // Always reset state to not listening
    this.isListening = false;
    this.updateMicrophoneButton(false);
    
    // If we received no results but were expecting them, inform the user
    if (this.expectingResults && !this.resultReceived) {
      console.log('Recognition ended without results');
      this.expectingResults = false;
      
      // Only show a message if we were in a continuous session
      // This avoids showing the message when the user just clicked the mic button to stop
      const micButton = document.getElementById('voice-command-toggle');
      const wasUIListening = micButton ? micButton.classList.contains('listening') : false;
      
      if (wasUIListening) {
        showToast('No speech detected. Please try again.', 'info');
      }
    }
    
    // Reset the results expectation flag for next session
    this.expectingResults = false;
    this.resultReceived = false;
  }

  /**
   * Update microphone button state
   * @param {boolean} isListening - Whether the app is listening for commands
   */
  updateMicrophoneButton(isListening) {
    const micButton = document.getElementById('voice-command-toggle');
    if (micButton) {
      if (isListening) {
        micButton.classList.add('listening');
        micButton.innerHTML = '<i class="bi bi-mic-fill text-danger"></i>';
        micButton.setAttribute('title', 'Stop listening');
      } else {
        micButton.classList.remove('listening');
        micButton.innerHTML = '<i class="bi bi-mic"></i>';
        micButton.setAttribute('title', 'Start voice commands');
      }
    }
  }

  /**
   * Process the voice command
   * @param {string} command - Voice command to process
   */
  processCommand(command) {
    if (!command) return;
    
    console.log('Processing command:', command);
    
    // Convert to lowercase for easier matching
    const lowerCommand = command.toLowerCase().trim();
    
    // Debug what was recognized
    showToast(`Heard: "${command}"`, 'info');
    
    // Check for "log" or "add" commands
    if (lowerCommand.includes('log') || lowerCommand.includes('add')) {
      // Find which type of data to log
      let handlerFound = false;
      for (const [key, handler] of Object.entries(this.commandHandlers)) {
        if (lowerCommand.includes(key)) {
          console.log(`Found handler for "${key}" command`);
          handlerFound = true;
          
          try {
            handler(lowerCommand);
          } catch (error) {
            console.error(`Error in ${key} command handler:`, error);
            showToast(`Error processing ${key} command: ${error.message}`, 'error');
          }
          return;
        }
      }
      
      // If no specific data type found
      if (!handlerFound) {
        console.warn('No matching command handler found for:', lowerCommand);
        showToast('Could not determine what to log. Try "log activity", "log meal", "log sleep", etc.', 'warning');
      }
    } else {
      showToast('Commands should start with "log" or "add". Try "log an activity" or "add a meal".', 'info');
    }
  }

  /**
   * Handle activity/workout command
   * @param {string} command - Voice command for activity
   */
  handleActivityCommand(command) {
    showToast('Processing activity command...', 'info');
    
    // Try to extract activity details from command
    const details = this.extractActivityDetails(command);
    
    // Check if the workout modal exists before proceeding
    const workoutModal = document.getElementById('addWorkoutModal');
    if (!workoutModal) {
      showToast('Activity tracking feature is not available on this page', 'warning');
      return;
    }
    
    if (details) {
      // Open the activity modal
      const addWorkoutModal = new bootstrap.Modal(workoutModal);
      addWorkoutModal.show();
      
      // Fill in the form fields with extracted data
      setTimeout(() => {
        if (details.name) {
          const nameInput = document.getElementById('workout-name');
          if (nameInput) nameInput.value = details.name;
        }
        
        if (details.type) {
          const typeSelect = document.getElementById('workout-type');
          if (typeSelect) {
            // Find closest match for workout type
            const types = ['running', 'cycling', 'swimming', 'weights'];
            const bestMatch = this.findBestMatch(details.type, types);
            if (bestMatch) {
              typeSelect.value = bestMatch;
              // Trigger change event to update form based on type
              typeSelect.dispatchEvent(new Event('change'));
            }
          }
        }
        
        if (details.duration) {
          const durationInput = document.getElementById('workout-duration');
          if (durationInput) durationInput.value = details.duration;
        }
        
        if (details.calories) {
          const caloriesInput = document.getElementById('workout-calories');
          if (caloriesInput) caloriesInput.value = details.calories;
        }
        
        if (details.distance) {
          const distanceInput = document.getElementById('workout-distance');
          if (distanceInput) distanceInput.value = details.distance;
        }
        
        // Alert the user what was filled
        let message = 'Activity form opened. I heard: ';
        message += details.name ? `Name: ${details.name}, ` : '';
        message += details.type ? `Type: ${details.type}, ` : '';
        message += details.duration ? `Duration: ${details.duration} min, ` : '';
        message += details.calories ? `Calories: ${details.calories}, ` : '';
        message += details.distance ? `Distance: ${details.distance}` : '';
        
        showToast(message, 'success');
      }, 500);
    } else if (workoutModal) {
      // If we couldn't extract details but the modal exists, open it
      const addWorkoutModal = new bootstrap.Modal(workoutModal);
      addWorkoutModal.show();
      showToast('Activity form opened. Please fill in the details.', 'info');
    }
  }

  /**
   * Extract activity details from command
   * @param {string} command - Activity command to parse
   * @returns {Object|null} Extracted activity details or null if couldn't parse
   */
  extractActivityDetails(command) {
    // Basic data extraction from voice command
    const result = {
      name: null,
      type: null,
      duration: null,
      calories: null,
      distance: null
    };
    
    // Extract activity name (anything after "called" or "named")
    const nameMatch = command.match(/(?:called|named)\s+([a-zA-Z0-9\s]+?)(?:\s+for|\s+with|\s+lasting|\s+burned|$)/i);
    if (nameMatch && nameMatch[1]) {
      result.name = nameMatch[1].trim();
    } else {
      // Try to find a default name based on the type of workout
      const typeWords = ['running', 'cycling', 'swimming', 'weights', 'workout', 'exercise'];
      for (const word of typeWords) {
        if (command.includes(word)) {
          result.name = `${word.charAt(0).toUpperCase() + word.slice(1)} workout`;
          break;
        }
      }
    }
    
    // Extract activity type
    const typeMatch = command.match(/(?:type|category)\s+(?:of\s+)?([a-zA-Z]+)/i);
    if (typeMatch && typeMatch[1]) {
      result.type = typeMatch[1].toLowerCase().trim();
    } else {
      // Try to infer type from the command
      const types = {
        running: ['run', 'running', 'jog', 'jogging'],
        cycling: ['cycle', 'cycling', 'bike', 'biking', 'bicycle'],
        swimming: ['swim', 'swimming'],
        weights: ['weight', 'weights', 'strength', 'lifting', 'gym']
      };
      
      for (const [type, keywords] of Object.entries(types)) {
        for (const keyword of keywords) {
          if (command.includes(keyword)) {
            result.type = type;
            break;
          }
        }
        if (result.type) break;
      }
    }
    
    // Extract duration
    const durationMatch = command.match(/(?:for|duration|lasting)\s+(\d+)\s*(?:min|minute|minutes)/i);
    if (durationMatch && durationMatch[1]) {
      result.duration = parseInt(durationMatch[1], 10);
    }
    
    // Extract calories
    const caloriesMatch = command.match(/(?:burned|burning)\s+(\d+)\s*(?:cal|calories)/i);
    if (caloriesMatch && caloriesMatch[1]) {
      result.calories = parseInt(caloriesMatch[1], 10);
    }
    
    // Extract distance
    const distanceMatch = command.match(/(\d+(?:\.\d+)?)\s*(?:km|kilometer|kilometers|mile|miles)/i);
    if (distanceMatch && distanceMatch[1]) {
      result.distance = parseFloat(distanceMatch[1]);
    }
    
    // If we couldn't extract anything meaningful, return null
    if (!result.name && !result.type && !result.duration && !result.calories && !result.distance) {
      return null;
    }
    
    return result;
  }

  /**
   * Handle nutrition/meal command
   * @param {string} command - Voice command for nutrition
   */
  handleNutritionCommand(command) {
    showToast('Processing nutrition command...', 'info');
    
    // Try to extract meal details from command
    const details = this.extractMealDetails(command);
    
    // Check if the meal modal exists before proceeding
    const mealModal = document.getElementById('addMealModal');
    if (!mealModal) {
      showToast('Nutrition tracking feature is not available on this page', 'warning');
      return;
    }
    
    if (details) {
      // Open the meal modal
      const addMealModal = new bootstrap.Modal(mealModal);
      addMealModal.show();
      
      // Fill in the form fields with extracted data
      setTimeout(() => {
        if (details.name) {
          const nameInput = document.getElementById('meal-name');
          if (nameInput) nameInput.value = details.name;
        }
        
        if (details.description) {
          const descInput = document.getElementById('meal-description');
          if (descInput) descInput.value = details.description;
        }
        
        if (details.category) {
          const categorySelect = document.getElementById('meal-category');
          if (categorySelect) {
            // Find closest match for meal category
            const categories = ['breakfast', 'lunch', 'dinner', 'snack', 'dessert'];
            const bestMatch = this.findBestMatch(details.category, categories);
            if (bestMatch) {
              categorySelect.value = bestMatch;
            }
          }
        }
        
        if (details.calories) {
          const caloriesInput = document.getElementById('meal-calories');
          if (caloriesInput) caloriesInput.value = details.calories;
        }
        
        if (details.protein) {
          const proteinInput = document.getElementById('meal-protein');
          if (proteinInput) proteinInput.value = details.protein;
        }
        
        if (details.carbs) {
          const carbsInput = document.getElementById('meal-carbs');
          if (carbsInput) carbsInput.value = details.carbs;
        }
        
        if (details.fat) {
          const fatInput = document.getElementById('meal-fat');
          if (fatInput) fatInput.value = details.fat;
        }
        
        // Alert the user what was filled
        let message = 'Meal form opened. I heard: ';
        message += details.name ? `Name: ${details.name}, ` : '';
        message += details.category ? `Category: ${details.category}, ` : '';
        message += details.calories ? `Calories: ${details.calories}, ` : '';
        message += details.protein ? `Protein: ${details.protein}g, ` : '';
        message += details.carbs ? `Carbs: ${details.carbs}g, ` : '';
        message += details.fat ? `Fat: ${details.fat}g` : '';
        
        showToast(message, 'success');
      }, 500);
    } else if (mealModal) {
      // If we couldn't extract details but the modal exists, open it
      const addMealModal = new bootstrap.Modal(mealModal);
      addMealModal.show();
      showToast('Meal form opened. Please fill in the details.', 'info');
    }
  }

  /**
   * Extract meal details from command
   * @param {string} command - Meal command to parse
   * @returns {Object|null} Extracted meal details or null if couldn't parse
   */
  extractMealDetails(command) {
    // Basic data extraction from voice command
    const result = {
      name: null,
      description: null,
      category: null,
      calories: null,
      protein: null,
      carbs: null,
      fat: null
    };
    
    // Extract meal name
    const nameMatch = command.match(/(?:called|named)\s+([a-zA-Z0-9\s]+?)(?:\s+with|\s+containing|\s+for|\s+having|$)/i);
    if (nameMatch && nameMatch[1]) {
      result.name = nameMatch[1].trim();
    } else {
      // Try to find a default name based on category mentioned
      const categories = ['breakfast', 'lunch', 'dinner', 'snack', 'dessert'];
      for (const category of categories) {
        if (command.includes(category)) {
          result.name = `${category.charAt(0).toUpperCase() + category.slice(1)} meal`;
          result.category = category;
          break;
        }
      }
    }
    
    // If no category was found by name, try to extract it directly
    if (!result.category) {
      const categoryMatch = command.match(/(?:category|type)\s+(?:is\s+)?([a-zA-Z]+)/i);
      if (categoryMatch && categoryMatch[1]) {
        result.category = categoryMatch[1].toLowerCase().trim();
      }
    }
    
    // Extract calories
    const caloriesMatch = command.match(/(\d+)\s*(?:cal|calories)/i);
    if (caloriesMatch && caloriesMatch[1]) {
      result.calories = parseInt(caloriesMatch[1], 10);
    }
    
    // Extract protein
    const proteinMatch = command.match(/(\d+)\s*(?:g|grams)?\s*(?:of\s+)?protein/i);
    if (proteinMatch && proteinMatch[1]) {
      result.protein = parseInt(proteinMatch[1], 10);
    }
    
    // Extract carbs
    const carbsMatch = command.match(/(\d+)\s*(?:g|grams)?\s*(?:of\s+)?(?:carbs|carbohydrates)/i);
    if (carbsMatch && carbsMatch[1]) {
      result.carbs = parseInt(carbsMatch[1], 10);
    }
    
    // Extract fat
    const fatMatch = command.match(/(\d+)\s*(?:g|grams)?\s*(?:of\s+)?fat/i);
    if (fatMatch && fatMatch[1]) {
      result.fat = parseInt(fatMatch[1], 10);
    }
    
    // If food items are mentioned, use them as description
    const foodMatch = command.match(/(?:containing|with|having|made of)\s+([a-zA-Z0-9\s,]+)(?:\s+with|\s+and|\s+has|\s+having|\s+containing|$)/i);
    if (foodMatch && foodMatch[1]) {
      result.description = foodMatch[1].trim();
    }
    
    // If we couldn't extract anything meaningful, return null
    if (!result.name && !result.category && !result.calories && 
        !result.protein && !result.carbs && !result.fat && !result.description) {
      return null;
    }
    
    return result;
  }

  /**
   * Handle sleep command
   * @param {string} command - Voice command for sleep
   */
  handleSleepCommand(command) {
    showToast('Processing sleep command...', 'info');
    
    // Try to extract sleep details from command
    const details = this.extractSleepDetails(command);
    
    // Check if the sleep modal exists before proceeding
    const sleepModal = document.getElementById('addSleepModal');
    if (!sleepModal) {
      showToast('Sleep tracking feature is not available on this page', 'warning');
      return;
    }
    
    if (details) {
      // Open the sleep modal
      const addSleepModal = new bootstrap.Modal(sleepModal);
      addSleepModal.show();
      
      // Fill in the form fields with extracted data
      setTimeout(() => {
        if (details.startTime) {
          const startTimeInput = document.getElementById('sleep-start');
          if (startTimeInput) startTimeInput.value = details.startTime;
        }
        
        if (details.endTime) {
          const endTimeInput = document.getElementById('sleep-end');
          if (endTimeInput) endTimeInput.value = details.endTime;
        }
        
        if (details.quality) {
          const qualitySelect = document.getElementById('sleep-quality');
          if (qualitySelect) qualitySelect.value = details.quality;
        }
        
        if (details.notes) {
          const notesInput = document.getElementById('sleep-notes');
          if (notesInput) notesInput.value = details.notes;
        }
        
        // Alert the user what was filled
        let message = 'Sleep form opened. I heard: ';
        message += details.startTime ? `Went to bed: ${details.startTime}, ` : '';
        message += details.endTime ? `Woke up: ${details.endTime}, ` : '';
        message += details.quality ? `Quality: ${details.quality}/5, ` : '';
        message += details.notes ? `Notes: ${details.notes}` : '';
        
        showToast(message, 'success');
      }, 500);
    } else if (sleepModal) {
      // If we couldn't extract details but the modal exists, open it
      const addSleepModal = new bootstrap.Modal(sleepModal);
      addSleepModal.show();
      showToast('Sleep form opened. Please fill in the details.', 'info');
    }
  }

  /**
   * Extract sleep details from command
   * @param {string} command - Sleep command to parse
   * @returns {Object|null} Extracted sleep details or null if couldn't parse
   */
  extractSleepDetails(command) {
    // Basic data extraction from voice command
    const result = {
      startTime: null,
      endTime: null,
      quality: null,
      notes: null
    };
    
    // Try different patterns for sleep start time
    const startPatterns = [
      // Pattern 1: Went to bed/fell asleep/slept at TIME
      /(?:went to bed|fell asleep|slept)(?:[ ]?at|[ ]?around|[ ]?by)? (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)/i,
      
      // Pattern 2: At TIME I went to bed/fell asleep
      /(?:at|around|by) (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)[ ]?(?:I|we)?[ ]?(?:went to bed|fell asleep|slept)/i,
      
      // Pattern 3: Bedtime was/at TIME
      /(?:bedtime|sleep time)[ ]?(?:was|at|around)? (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)/i,
      
      // Pattern 4: Sleep start/begin at TIME
      /(?:sleep|sleeping)[ ]?(?:start|started|begin|began|from)[ ]?(?:at|around|by)? (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)/i,
      
      // Pattern 5: From TIME to TIME (extracting first time)
      /(?:from|between) (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)[ ]?(?:to|until|and)/i
    ];
    
    // Try each pattern until one matches
    for (const pattern of startPatterns) {
      const match = command.match(pattern);
      if (match && match[1]) {
        result.startTime = this.formatTimeForInput(match[1]);
        if (result.startTime) break;
      }
    }
    
    // Handle special keywords for bedtime
    if (!result.startTime) {
      if (command.includes('midnight') && !command.includes('woke up at midnight')) {
        result.startTime = '00:00';
      } else if (command.includes('late') && !command.includes('woke up late')) {
        // Late usually means after midnight
        result.startTime = '00:30';
      }
    }
    
    // Try different patterns for wake time
    const endPatterns = [
      // Pattern 1: Woke up/got up/awoke at TIME
      /(?:woke up|got up|awoke|waken(?:ed)?)(?:[ ]?at|[ ]?around|[ ]?by)? (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)/i,
      
      // Pattern 2: At TIME I woke up/got up
      /(?:at|around|by) (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)[ ]?(?:I|we)?[ ]?(?:woke up|got up|awoke)/i,
      
      // Pattern 3: Wake time was/at TIME
      /(?:wake time|wake-up time)[ ]?(?:was|at|around)? (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)/i,
      
      // Pattern 4: Sleep end/until TIME
      /(?:sleep|sleeping)[ ]?(?:end|ended|until|to)[ ]?(?:at|around|by)? (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)/i,
      
      // Pattern 5: From TIME to TIME (extracting second time)
      /(?:to|until|and) (\d{1,2}(?::\d{2})?(?:[ ]?[ap]\.?m\.?)?)/i
    ];
    
    // Try each pattern until one matches
    for (const pattern of endPatterns) {
      const match = command.match(pattern);
      if (match && match[1]) {
        result.endTime = this.formatTimeForInput(match[1]);
        if (result.endTime) break;
      }
    }
    
    // Handle special keywords for wake time
    if (!result.endTime) {
      if (command.includes('early morning')) {
        result.endTime = '06:00';
      } else if (command.includes('morning')) {
        result.endTime = '07:30';
      }
    }
    
    // Extract sleep quality
    const qualityMatch = command.match(/(?:quality|rating|score) (?:of|was) (\d)/i);
    if (qualityMatch && qualityMatch[1]) {
      const quality = parseInt(qualityMatch[1], 10);
      if (quality >= 1 && quality <= 5) {
        result.quality = quality;
      }
    } else {
      // Try to infer quality from descriptive words
      const qualityWords = {
        1: ['terrible', 'awful', 'very bad', 'horrible', 'worst'],
        2: ['bad', 'poor', 'not good'],
        3: ['okay', 'average', 'decent', 'fine', 'alright'],
        4: ['good', 'restful', 'nice', 'well'],
        5: ['excellent', 'amazing', 'great', 'perfect', 'best']
      };
      
      for (const [rating, words] of Object.entries(qualityWords)) {
        for (const word of words) {
          if (command.includes(word)) {
            result.quality = parseInt(rating, 10);
            break;
          }
        }
        if (result.quality) break;
      }
    }
    
    // Extract sleep notes
    const notesMatch = command.match(/(?:notes|note|comments)(?:\s+(?:saying|that|about))?\s+([^,.]+)/i);
    if (notesMatch && notesMatch[1]) {
      result.notes = notesMatch[1].trim();
    }
    
    // If we couldn't extract anything meaningful, return null
    if (!result.startTime && !result.endTime && !result.quality && !result.notes) {
      return null;
    }
    
    return result;
  }

  /**
   * Handle habit command
   * @param {string} command - Voice command for habits
   */
  handleHabitCommand(command) {
    showToast('Processing habit command...', 'info');
    
    // Try to extract habit details from command
    const details = this.extractHabitDetails(command);
    
    // Check if the habit modal exists before proceeding
    const habitModal = document.getElementById('addHabitModal');
    if (!habitModal) {
      showToast('Habit tracking feature is not available on this page', 'warning');
      return;
    }
    
    if (details) {
      // Open the habit modal
      const addHabitModal = new bootstrap.Modal(habitModal);
      addHabitModal.show();
      
      // Fill in the form fields with extracted data
      setTimeout(() => {
        if (details.name) {
          const nameInput = document.getElementById('habit-name');
          if (nameInput) nameInput.value = details.name;
        }
        
        if (details.description) {
          const descInput = document.getElementById('habit-description');
          if (descInput) descInput.value = details.description;
        }
        
        if (details.frequency) {
          const freqInput = document.getElementById('habit-frequency');
          if (freqInput) freqInput.value = details.frequency;
        }
        
        if (details.frequencyUnit) {
          const freqUnitSelect = document.getElementById('habit-frequency-unit');
          if (freqUnitSelect) freqUnitSelect.value = details.frequencyUnit;
        }
        
        if (details.category) {
          const categorySelect = document.getElementById('habit-category');
          if (categorySelect) {
            // Find closest match for habit category
            const categories = ['smoking', 'drinking', 'junk food', 'social media', 'other'];
            const bestMatch = this.findBestMatch(details.category, categories);
            if (bestMatch) {
              categorySelect.value = bestMatch;
            }
          }
        }
        
        if (details.trigger) {
          const triggerInput = document.getElementById('habit-trigger');
          if (triggerInput) triggerInput.value = details.trigger;
        }
        
        if (details.alternative) {
          const alternativeInput = document.getElementById('habit-alternative');
          if (alternativeInput) alternativeInput.value = details.alternative;
        }
        
        // Alert the user what was filled
        let message = 'Habit form opened. I heard: ';
        message += details.name ? `Name: ${details.name}, ` : '';
        message += details.frequency && details.frequencyUnit ? 
            `Frequency: ${details.frequency} ${details.frequencyUnit}, ` : '';
        message += details.category ? `Category: ${details.category}, ` : '';
        message += details.trigger ? `Trigger: ${details.trigger}, ` : '';
        message += details.alternative ? `Alternative: ${details.alternative}` : '';
        
        showToast(message, 'success');
      }, 500);
    } else if (habitModal) {
      // If we couldn't extract details but the modal exists, open it
      const addHabitModal = new bootstrap.Modal(habitModal);
      addHabitModal.show();
      showToast('Habit form opened. Please fill in the details.', 'info');
    }
  }

  /**
   * Extract habit details from command
   * @param {string} command - Habit command to parse
   * @returns {Object|null} Extracted habit details or null if couldn't parse
   */
  extractHabitDetails(command) {
    // Basic data extraction from voice command
    const result = {
      name: null,
      description: null,
      frequency: null,
      frequencyUnit: null,
      category: null,
      trigger: null,
      alternative: null
    };
    
    // Extract habit name
    const nameMatch = command.match(/(?:called|named)\s+([a-zA-Z0-9\s]+?)(?:\s+with|\s+because|\s+about|\s+that|$)/i);
    if (nameMatch && nameMatch[1]) {
      result.name = nameMatch[1].trim();
    } else {
      // Try to infer a name from the category or description
      const categories = ['smoking', 'drinking', 'junk food', 'social media'];
      for (const category of categories) {
        if (command.includes(category)) {
          result.name = `Reduce ${category}`;
          result.category = category;
          break;
        }
      }
    }
    
    // Extract frequency
    const frequencyMatch = command.match(/(\d+)\s+(?:times|time)\s+(?:per|a|each)\s+(day|week)/i);
    if (frequencyMatch && frequencyMatch[1] && frequencyMatch[2]) {
      result.frequency = parseInt(frequencyMatch[1], 10);
      result.frequencyUnit = frequencyMatch[2].toLowerCase() === 'day' ? 'daily' : 'weekly';
    }
    
    // If no category was found by name, try to extract it directly
    if (!result.category) {
      const categoryMatch = command.match(/(?:category|type)\s+(?:is\s+)?([a-zA-Z\s]+?)(?:\s+and|\s+with|\s+triggered|$)/i);
      if (categoryMatch && categoryMatch[1]) {
        result.category = categoryMatch[1].toLowerCase().trim();
      }
    }
    
    // Extract trigger
    const triggerMatch = command.match(/(?:triggered|happens|occurs)\s+(?:by|when|during)\s+([^,.]+?)(?:\s+and|\s+with|\s+alternative|$)/i);
    if (triggerMatch && triggerMatch[1]) {
      result.trigger = triggerMatch[1].trim();
    }
    
    // Extract alternative
    const alternativeMatch = command.match(/(?:alternative|instead|replace with|substitute)\s+(?:is|with)?\s+([^,.]+?)(?:\s+and|\s+with|$)/i);
    if (alternativeMatch && alternativeMatch[1]) {
      result.alternative = alternativeMatch[1].trim();
    }
    
    // Extract description (if explicit)
    const descMatch = command.match(/(?:description|about|reason)\s+(?:is|says)?\s+([^,.]+?)(?:\s+and|\s+with|$)/i);
    if (descMatch && descMatch[1]) {
      result.description = descMatch[1].trim();
    }
    
    // If we couldn't extract anything meaningful, return null
    if (!result.name && !result.frequency && !result.category && 
        !result.trigger && !result.alternative && !result.description) {
      return null;
    }
    
    return result;
  }

  /**
   * Handle steps command
   * @param {string} command - Voice command for steps
   */
  handleStepsCommand(command) {
    showToast('Processing steps command...', 'info');
    
    // Try to extract steps count from command
    const details = this.extractStepsDetails(command);
    
    // Check if the steps modal exists before proceeding
    const stepsModal = document.getElementById('addStepsModal');
    if (!stepsModal) {
      showToast('Steps tracking feature is not available on this page', 'warning');
      return;
    }
    
    if (details && details.steps) {
      // Open the steps modal
      const addStepsModal = new bootstrap.Modal(stepsModal);
      addStepsModal.show();
      
      // Fill in the form fields with extracted data
      setTimeout(() => {
        const stepsInput = document.getElementById('steps-count');
        if (stepsInput) stepsInput.value = details.steps;
        
        showToast(`Steps form opened. I heard: ${details.steps} steps.`, 'success');
      }, 500);
    } else {
      // If we couldn't extract details but the modal exists, open it
      const addStepsModal = new bootstrap.Modal(stepsModal);
      addStepsModal.show();
      showToast('Steps form opened. Please enter the number of steps.', 'info');
    }
  }

  /**
   * Extract steps details from command
   * @param {string} command - Steps command to parse
   * @returns {Object|null} Extracted steps details or null if couldn't parse
   */
  extractStepsDetails(command) {
    // Extract steps count
    const stepsMatch = command.match(/(\d+,?\d*)\s+(?:steps)/i);
    if (stepsMatch && stepsMatch[1]) {
      // Remove commas and convert to number
      const steps = parseInt(stepsMatch[1].replace(/,/g, ''), 10);
      return { steps };
    }
    return null;
  }

  /**
   * Format time string for input field
   * @param {string} timeStr - Time string like "10:30 pm"
   * @returns {string} Formatted time for input field (HH:MM)
   */
  formatTimeForInput(timeStr) {
    try {
      // Remove any spaces
      let time = timeStr.trim().toLowerCase();
      
      // Handle times without minutes like "10 pm"
      if (!time.includes(':')) {
        time = time.replace(/(\d+)(\s*[ap]m)/, '$1:00$2');
      }
      
      // Handle special cases like "midnight" and "noon"
      if (time.includes('midnight')) {
        return '00:00';
      } else if (time.includes('noon')) {
        return '12:00';
      }
      
      // Better regex to handle various time formats
      const match = time.match(/(\d{1,2})(?::(\d{2}))?(?:\s*([ap]\.?m\.?)?)/i);
      if (!match) {
        console.warn(`Could not parse time: ${timeStr}`);
        return null;
      }
      
      let hours = parseInt(match[1], 10);
      // If hours is invalid, default to a reasonable value
      if (isNaN(hours) || hours > 12) {
        console.warn(`Invalid hours in time: ${timeStr}`);
        hours = 8; // Default to 8 AM or 8 PM based on period
      }
      
      const minutes = match[2] ? parseInt(match[2], 10) : 0;
      // If minutes is invalid, default to 0
      if (isNaN(minutes) || minutes >= 60) {
        console.warn(`Invalid minutes in time: ${timeStr}`);
        minutes = 0;
      }
      
      // Default period based on common sleep/wake times
      let period;
      if (match[3]) {
        period = match[3].toLowerCase().includes('p') ? 'pm' : 'am';
      } else {
        // Default to PM for hours 6-11 (more likely to be bedtime)
        // Default to AM for hours 1-5, 12 (more likely to be wake time)
        period = (hours >= 6 && hours <= 11) ? 'pm' : 'am';
      }
      
      // Convert to 24-hour format
      if (period === 'pm' && hours < 12) {
        hours += 12;
      } else if (period === 'am' && hours === 12) {
        hours = 0;
      }
      
      // Format as HH:MM for the input field
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    } catch (e) {
      console.error('Error formatting time input:', e);
      return null;
    }
  }

  /**
   * Find the best match from a list of options
   * @param {string} input - The input string to match
   * @param {string[]} options - Array of options to match against
   * @returns {string|null} The best matching option or null if no good match
   */
  findBestMatch(input, options) {
    if (!input || !options || options.length === 0) return null;
    
    // Simple matching algorithm - can be improved with more sophisticated methods
    const inputLower = input.toLowerCase();
    
    // First check for exact matches
    for (const option of options) {
      if (option.toLowerCase() === inputLower) {
        return option;
      }
    }
    
    // Then check for partial matches
    for (const option of options) {
      if (option.toLowerCase().includes(inputLower) || inputLower.includes(option.toLowerCase())) {
        return option;
      }
    }
    
    // No good match found
    return null;
  }
}

// We'll use the app.js initialization instead of this one to avoid conflicts
// The speech recognition is initialized in app.js via initializeSpeechRecognition()
// This event listener is kept for backwards compatibility with pages that don't include app.js
document.addEventListener('DOMContentLoaded', function() {
  // Only initialize if not already done in app.js
  if (!window.speechRecognizer) {
    console.log('Initializing speech recognition from speech-recognition.js');
    window.speechRecognizer = new SpeechRecognizer();
    
    // Add the microphone button to the navbar if it doesn't exist
    addMicrophoneButton();
    
    console.log('Speech recognition functionality loaded');
  } else {
    console.log('Speech recognition already initialized by app.js');
  }
});

/**
 * Add microphone button to the navigation bar
 * Exposed globally for dark mode and other modules
 */
window.addMicrophoneButton = function() {
  // Check if button already exists
  if (document.getElementById('voice-command-toggle')) return;
  
  const navbarNav = document.querySelector('.navbar-nav');
  if (!navbarNav) return;
  
  // Add microphone button
  const micButtonItem = document.createElement('li');
  micButtonItem.className = 'nav-item ms-2';
  
  const micButton = document.createElement('button');
  micButton.id = 'voice-command-toggle';
  micButton.className = 'btn btn-outline-light';
  micButton.setAttribute('title', 'Start voice commands');
  micButton.innerHTML = '<i class="bi bi-mic"></i>';
  
  micButton.addEventListener('click', function() {
    if (window.speechRecognizer) {
      window.speechRecognizer.toggleListening();
    }
  });
  
  micButtonItem.appendChild(micButton);
  navbarNav.appendChild(micButtonItem);
  
  // Add help button
  const helpButtonItem = document.createElement('li');
  helpButtonItem.className = 'nav-item ms-2';
  
  const helpButton = document.createElement('button');
  helpButton.id = 'voice-command-help';
  helpButton.className = 'btn btn-outline-light';
  helpButton.setAttribute('title', 'Voice command help');
  helpButton.innerHTML = '<i class="bi bi-question-circle"></i>';
  
  helpButton.addEventListener('click', function() {
    const helpModal = new bootstrap.Modal(document.getElementById('voiceCommandHelpModal'));
    helpModal.show();
  });
  
  helpButtonItem.appendChild(helpButton);
  navbarNav.appendChild(helpButtonItem);
}