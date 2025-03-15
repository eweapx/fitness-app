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
    
    // Command handlers for different types of data
    this.commandHandlers = {
      'activity': this.handleActivityCommand,
      'workout': this.handleActivityCommand, // Alias for activity
      'exercise': this.handleActivityCommand, // Alias for activity
      'nutrition': this.handleNutritionCommand,
      'meal': this.handleNutritionCommand, // Alias for nutrition
      'food': this.handleNutritionCommand, // Alias for nutrition
      'sleep': this.handleSleepCommand,
      'habit': this.handleHabitCommand,
      'steps': this.handleStepsCommand
    };
    
    this.initializeSpeechRecognition();
  }

  /**
   * Initialize the speech recognition API
   */
  initializeSpeechRecognition() {
    // Check for browser support
    if ('SpeechRecognition' in window || 'webkitSpeechRecognition' in window) {
      // Create speech recognition instance
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      this.recognition = new SpeechRecognition();
      
      // Configure recognition
      this.recognition.continuous = false;
      this.recognition.interimResults = false;
      this.recognition.lang = 'en-US';
      
      // Set up event handlers
      this.recognition.onstart = this.handleRecognitionStart.bind(this);
      this.recognition.onresult = this.handleRecognitionResult.bind(this);
      this.recognition.onerror = this.handleRecognitionError.bind(this);
      this.recognition.onend = this.handleRecognitionEnd.bind(this);
      
      this.voiceCommandsEnabled = true;
      console.log('Speech recognition initialized successfully');
    } else {
      console.error('Speech recognition not supported in this browser');
      this.voiceCommandsEnabled = false;
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
    
    if (this.isListening) {
      this.stopListening();
    } else {
      this.startListening();
    }
  }

  /**
   * Start listening for voice commands
   */
  startListening() {
    if (!this.voiceCommandsEnabled) return;
    
    try {
      // Only start if not already listening to avoid InvalidStateError
      if (!this.isListening) {
        this.recognition.start();
        this.updateMicrophoneButton(true);
      }
    } catch (error) {
      console.error('Error starting speech recognition:', error);
      this.updateMicrophoneButton(false);
      showToast('Could not start speech recognition', 'error');
    }
  }

  /**
   * Stop listening for voice commands
   */
  stopListening() {
    if (!this.voiceCommandsEnabled) return;
    
    try {
      // Only stop if currently listening to avoid InvalidStateError
      if (this.isListening) {
        this.recognition.stop();
        this.updateMicrophoneButton(false);
      }
    } catch (error) {
      console.error('Error stopping speech recognition:', error);
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
    this.isListening = false;
    this.updateMicrophoneButton(false);
    
    let errorMessage = 'Speech recognition error';
    switch (event.error) {
      case 'no-speech':
        errorMessage = 'No speech detected';
        break;
      case 'aborted':
        errorMessage = 'Recognition aborted';
        break;
      case 'audio-capture':
        errorMessage = 'Could not capture audio';
        break;
      case 'network':
        errorMessage = 'Network error';
        break;
      case 'not-allowed':
        errorMessage = 'Microphone access denied';
        break;
      case 'service-not-allowed':
        errorMessage = 'Service not allowed';
        break;
      case 'bad-grammar':
        errorMessage = 'Bad grammar configuration';
        break;
      case 'language-not-supported':
        errorMessage = 'Language not supported';
        break;
    }
    
    showToast(errorMessage, 'error');
  }

  /**
   * Handle recognition end event
   */
  handleRecognitionEnd() {
    this.isListening = false;
    this.updateMicrophoneButton(false);
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
    
    // Convert to lowercase for easier matching
    const lowerCommand = command.toLowerCase().trim();
    
    // Check for "log" or "add" commands
    if (lowerCommand.includes('log') || lowerCommand.includes('add')) {
      // Find which type of data to log
      for (const [key, handler] of Object.entries(this.commandHandlers)) {
        if (lowerCommand.includes(key)) {
          handler.call(this, lowerCommand);
          return;
        }
      }
      
      // If no specific data type found
      showToast('Could not determine what to log. Try "log activity", "log meal", "log sleep", etc.', 'warning');
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
    
    // Extract sleep start time
    const startMatch = command.match(/(?:went to bed|fell asleep|slept) (?:at|around) (\d{1,2}(?::\d{2})?\s*(?:am|pm))/i);
    if (startMatch && startMatch[1]) {
      // Format time for input field (HH:MM)
      result.startTime = this.formatTimeForInput(startMatch[1]);
    }
    
    // Extract sleep end time
    const endMatch = command.match(/(?:woke up|got up|awoke) (?:at|around) (\d{1,2}(?::\d{2})?\s*(?:am|pm))/i);
    if (endMatch && endMatch[1]) {
      // Format time for input field (HH:MM)
      result.endTime = this.formatTimeForInput(endMatch[1]);
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
    // Remove any spaces
    let time = timeStr.trim().toLowerCase();
    
    // Handle times without minutes like "10 pm"
    if (!time.includes(':')) {
      time = time.replace(/(\d+)(\s*[ap]m)/, '$1:00$2');
    }
    
    // Parse the time components
    const match = time.match(/(\d{1,2}):?(\d{2})?\s*([ap]m)?/);
    if (!match) return null;
    
    let hours = parseInt(match[1], 10);
    const minutes = match[2] ? parseInt(match[2], 10) : 0;
    const period = match[3] || 'am'; // Default to AM if not specified
    
    // Convert to 24-hour format
    if (period.toLowerCase() === 'pm' && hours < 12) {
      hours += 12;
    } else if (period.toLowerCase() === 'am' && hours === 12) {
      hours = 0;
    }
    
    // Format as HH:MM for the input field
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
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

// Initialize speech recognition on page load
document.addEventListener('DOMContentLoaded', function() {
  // Create the speech recognizer
  window.speechRecognizer = new SpeechRecognizer();
  
  // Add the microphone button to the navbar if it doesn't exist
  addMicrophoneButton();
  
  console.log('Speech recognition functionality loaded');
});

/**
 * Add microphone button to the navigation bar
 */
function addMicrophoneButton() {
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