/**
 * Form Speech Input
 * This module provides speech-to-text functionality for form inputs
 */

class FormSpeechInput {
  constructor() {
    this.isListening = false;
    this.targetInput = null;
    this.stopTimeout = null;
    this.inactivityTimeout = 5000; // Stop after 5 seconds of silence
    
    this.initializeSpeechRecognition();
    this.setupSpeechButtons();
  }
  
  /**
   * Initialize the speech recognition API
   */
  initializeSpeechRecognition() {
    console.log('Initializing form speech input...');
    
    // Check for browser support
    if ('SpeechRecognition' in window || 'webkitSpeechRecognition' in window) {
      try {
        // Create speech recognition instance
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        this.recognition = new SpeechRecognition();
        
        // Configure recognition for form input
        this.recognition.continuous = true;
        this.recognition.interimResults = true;
        this.recognition.lang = 'en-US';
        
        // Set up event handlers with explicit binding to maintain context
        this.recognition.onstart = this.handleRecognitionStart.bind(this);
        this.recognition.onresult = this.handleRecognitionResult.bind(this);
        this.recognition.onerror = this.handleRecognitionError.bind(this);
        this.recognition.onend = this.handleRecognitionEnd.bind(this);
        
        this.speechEnabled = true;
        console.log('Form speech input initialized successfully');
      } catch (error) {
        console.error('Error initializing form speech input:', error);
        this.speechEnabled = false;
      }
    } else {
      console.error('Speech recognition not supported in this browser');
      this.speechEnabled = false;
    }
  }
  
  /**
   * Find all form inputs that should have speech input and add buttons
   */
  setupSpeechButtons() {
    // Add speech input buttons to eligible text inputs and textareas
    document.addEventListener('DOMContentLoaded', () => {
      this.addSpeechButtonsToForms();
      
      // Re-add buttons when new content is loaded via AJAX
      // Use MutationObserver to detect DOM changes
      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.addedNodes.length) {
            this.addSpeechButtonsToForms();
          }
        });
      });
      
      observer.observe(document.body, { childList: true, subtree: true });
    });
  }
  
  /**
   * Add speech buttons to all eligible form fields
   */
  addSpeechButtonsToForms() {
    // Find all text inputs, number inputs, date inputs, time inputs, textareas, and select dropdowns
    const eligibleInputs = document.querySelectorAll('input[type="text"], input[type="number"], input[type="date"], input[type="time"], textarea, select');
    
    eligibleInputs.forEach(input => {
      // Skip if already has speech button
      if (input.parentNode.querySelector('.speech-input-btn')) {
        return;
      }
      
      // Create wrapper if needed
      let wrapper = input.parentNode;
      if (!wrapper.classList.contains('input-group')) {
        // Create a wrapper for the input
        wrapper = document.createElement('div');
        wrapper.className = 'input-group';
        input.parentNode.insertBefore(wrapper, input);
        wrapper.appendChild(input);
      }
      
      // Create speech button
      const speechBtn = document.createElement('button');
      speechBtn.type = 'button';
      speechBtn.className = 'btn btn-outline-secondary speech-input-btn';
      speechBtn.innerHTML = '<i class="bi bi-mic"></i>';
      speechBtn.title = 'Speak to input text';
      speechBtn.setAttribute('data-target-input', input.id || this.generateInputId(input));
      
      // Create stop button (initially hidden)
      const stopBtn = document.createElement('button');
      stopBtn.type = 'button';
      stopBtn.className = 'btn btn-danger speech-stop-btn d-none';
      stopBtn.innerHTML = '<i class="bi bi-stop-fill"></i>';
      stopBtn.title = 'Stop listening';
      stopBtn.setAttribute('data-target-input', input.id || this.generateInputId(input));
      
      // Add buttons to the group
      const btnGroup = document.createElement('div');
      btnGroup.className = 'input-group-append';
      btnGroup.appendChild(speechBtn);
      btnGroup.appendChild(stopBtn);
      wrapper.appendChild(btnGroup);
      
      // Add event listeners
      speechBtn.addEventListener('click', (e) => {
        e.preventDefault();
        this.startListeningForInput(input, speechBtn, stopBtn);
      });
      
      stopBtn.addEventListener('click', (e) => {
        e.preventDefault();
        this.stopListening(speechBtn, stopBtn);
      });
    });
  }
  
  /**
   * Generate a unique ID for an input if it doesn't have one
   */
  generateInputId(input) {
    const id = 'speech-input-' + Math.random().toString(36).substring(2, 9);
    input.id = id;
    return id;
  }
  
  /**
   * Start listening for speech input
   * @param {HTMLElement} inputElement - The input element to fill with speech
   * @param {HTMLElement} micButton - The microphone button
   * @param {HTMLElement} stopButton - The stop button
   */
  startListeningForInput(inputElement, micButton, stopButton) {
    if (!this.speechEnabled) {
      showToast('Speech recognition is not supported in your browser', 'error');
      return;
    }
    
    // Stop any existing session
    if (this.isListening) {
      this.stopListening();
    }
    
    try {
      // Set the target input
      this.targetInput = inputElement;
      
      // Save the original value as the starting point
      this.originalInputValue = inputElement.value;
      this.finalTranscript = inputElement.value;
      this.interimTranscript = '';
      
      // Show visual feedback
      micButton.classList.add('d-none');
      stopButton.classList.remove('d-none');
      inputElement.classList.add('speech-active');
      
      // Start recognition
      this.recognition.start();
      console.log('Started listening for form input');
      
      // Create a status label
      this.createStatusLabel(inputElement);
      
      // Set timeout to automatically stop after period of silence
      this.resetInactivityTimer();
      
    } catch (error) {
      console.error('Error starting speech input:', error);
      this.showSpeechError(error);
      this.resetButtonState(micButton, stopButton);
    }
  }
  
  /**
   * Create a status label to show listening status
   */
  createStatusLabel(inputElement) {
    // Remove any existing label
    const existingLabel = document.getElementById('speech-status-label');
    if (existingLabel) {
      existingLabel.remove();
    }
    
    // Create new label
    const statusLabel = document.createElement('div');
    statusLabel.id = 'speech-status-label';
    statusLabel.className = 'form-text text-info small mt-1 mb-2';
    statusLabel.innerHTML = '<i class="bi bi-mic-fill text-danger"></i> Listening... (speak now)';
    
    // Insert after the input group
    const inputGroup = inputElement.closest('.input-group');
    inputGroup.parentNode.insertBefore(statusLabel, inputGroup.nextSibling);
  }
  
  /**
   * Reset the inactivity timer
   */
  resetInactivityTimer() {
    // Clear any existing timeout
    if (this.stopTimeout) {
      clearTimeout(this.stopTimeout);
    }
    
    // Set new timeout
    this.stopTimeout = setTimeout(() => {
      console.log('Speech input stopped due to inactivity');
      
      // Find the buttons for the current target input
      const inputGroup = this.targetInput.closest('.input-group');
      const micButton = inputGroup.querySelector('.speech-input-btn');
      const stopButton = inputGroup.querySelector('.speech-stop-btn');
      
      this.stopListening(micButton, stopButton);
      
      // Show a message
      const statusLabel = document.getElementById('speech-status-label');
      if (statusLabel) {
        statusLabel.className = 'form-text text-muted small mt-1 mb-2';
        statusLabel.innerHTML = 'Stopped listening due to silence';
        
        // Remove the message after 3 seconds
        setTimeout(() => {
          statusLabel.remove();
        }, 3000);
      }
    }, this.inactivityTimeout);
  }
  
  /**
   * Stop listening for speech input
   * @param {HTMLElement} micButton - The microphone button
   * @param {HTMLElement} stopButton - The stop button
   */
  stopListening(micButton, stopButton) {
    if (!this.isListening) return;
    
    try {
      // Stop the recognition
      this.recognition.stop();
      console.log('Stopped listening for form input');
      
      // Clear any active timeout
      if (this.stopTimeout) {
        clearTimeout(this.stopTimeout);
        this.stopTimeout = null;
      }
      
      // Reset button state if provided
      if (micButton && stopButton) {
        this.resetButtonState(micButton, stopButton);
      } else if (this.targetInput) {
        // Find the buttons for the current target input
        const inputGroup = this.targetInput.closest('.input-group');
        if (inputGroup) {
          const mic = inputGroup.querySelector('.speech-input-btn');
          const stop = inputGroup.querySelector('.speech-stop-btn');
          if (mic && stop) {
            this.resetButtonState(mic, stop);
          }
        }
      }
      
      // Remove status label
      const statusLabel = document.getElementById('speech-status-label');
      if (statusLabel) {
        statusLabel.remove();
      }
      
    } catch (error) {
      console.error('Error stopping speech input:', error);
    }
  }
  
  /**
   * Reset button state
   */
  resetButtonState(micButton, stopButton) {
    if (micButton) micButton.classList.remove('d-none');
    if (stopButton) stopButton.classList.add('d-none');
    if (this.targetInput) {
      this.targetInput.classList.remove('speech-active');
    }
  }
  
  /**
   * Handle recognition start event
   */
  handleRecognitionStart(event) {
    this.isListening = true;
    console.log('Recognition started for form input');
  }
  
  /**
   * Handle recognition result event
   */
  handleRecognitionResult(event) {
    // Reset the inactivity timer on new speech
    this.resetInactivityTimer();
    
    // Process results
    this.interimTranscript = '';
    
    for (let i = event.resultIndex; i < event.results.length; ++i) {
      if (event.results[i].isFinal) {
        this.finalTranscript += ' ' + event.results[i][0].transcript;
      } else {
        this.interimTranscript += event.results[i][0].transcript;
      }
    }
    
    // Clean up spacing
    this.finalTranscript = this.finalTranscript.trim();
    
    // Update the input with the transcribed text
    if (this.targetInput) {
      // Process special input types
      const inputType = this.targetInput.type;
      const fullTranscript = this.finalTranscript + 
                          (this.interimTranscript ? ' ' + this.interimTranscript : '');
      
      if (inputType === 'date') {
        // Try to parse a date from the speech
        const dateValue = this.tryParseDateFromSpeech(fullTranscript);
        if (dateValue) {
          this.targetInput.value = dateValue;
        }
      } else if (inputType === 'time') {
        // Try to parse a time from the speech
        const timeValue = this.tryParseTimeFromSpeech(fullTranscript);
        if (timeValue) {
          this.targetInput.value = timeValue;
        }
      } else if (inputType === 'number') {
        // Try to extract a number from the speech
        const numberValue = this.tryParseNumberFromSpeech(fullTranscript);
        if (numberValue !== null) {
          this.targetInput.value = numberValue;
        }
      } else if (this.targetInput.tagName.toLowerCase() === 'select') {
        // Handle select dropdowns
        this.handleSelectInput(fullTranscript);
      } else {
        // For text and textarea inputs, use the full transcript
        this.targetInput.value = fullTranscript;
      }
      
      // Update status label with interim results
      const statusLabel = document.getElementById('speech-status-label');
      if (statusLabel && this.interimTranscript) {
        statusLabel.innerHTML = '<i class="bi bi-mic-fill text-danger"></i> Hearing: ' + 
                               this.interimTranscript;
      } else if (statusLabel) {
        statusLabel.innerHTML = '<i class="bi bi-mic-fill text-danger"></i> Listening... (speak now)';
      }
    }
  }
  
  /**
   * Handle recognition error event
   */
  handleRecognitionError(event) {
    console.error('Speech recognition error:', event.error);
    
    const statusLabel = document.getElementById('speech-status-label');
    if (statusLabel) {
      let errorMessage = 'Error in speech recognition';
      
      switch (event.error) {
        case 'no-speech':
          errorMessage = 'No speech detected. Please try again.';
          break;
        case 'aborted':
          errorMessage = 'Recognition aborted.';
          break;
        case 'audio-capture':
          errorMessage = 'Could not capture audio. Please check your microphone.';
          break;
        case 'network':
          errorMessage = 'Network error occurred. Please check your connection.';
          break;
        case 'not-allowed':
          errorMessage = 'Microphone access denied. Please check browser permissions.';
          break;
      }
      
      statusLabel.className = 'form-text text-danger small mt-1 mb-2';
      statusLabel.textContent = errorMessage;
    }
    
    // Reset state
    if (this.targetInput) {
      const inputGroup = this.targetInput.closest('.input-group');
      const micButton = inputGroup.querySelector('.speech-input-btn');
      const stopButton = inputGroup.querySelector('.speech-stop-btn');
      this.resetButtonState(micButton, stopButton);
    }
    
    this.isListening = false;
  }
  
  /**
   * Handle recognition end event
   */
  handleRecognitionEnd(event) {
    console.log('Recognition ended for form input');
    this.isListening = false;
    
    // Update the status label
    const statusLabel = document.getElementById('speech-status-label');
    if (statusLabel) {
      statusLabel.className = 'form-text text-success small mt-1 mb-2';
      statusLabel.innerHTML = '<i class="bi bi-check-circle"></i> Finished recording';
      
      // Remove the label after 3 seconds
      setTimeout(() => {
        statusLabel.remove();
      }, 3000);
    }
    
    // Find the buttons for the current target input
    if (this.targetInput) {
      const inputGroup = this.targetInput.closest('.input-group');
      if (inputGroup) {
        const micButton = inputGroup.querySelector('.speech-input-btn');
        const stopButton = inputGroup.querySelector('.speech-stop-btn');
        this.resetButtonState(micButton, stopButton);
      }
      
      // Trigger change event on the input
      const event = new Event('change', { bubbles: true });
      this.targetInput.dispatchEvent(event);
      
      // Reset state
      this.targetInput = null;
    }
  }
  
  /**
   * Show a speech error
   */
  showSpeechError(error) {
    let message = 'Speech recognition error';
    
    if (error.name === 'NotAllowedError') {
      message = 'Microphone access denied. Please allow access in your browser settings.';
    } else if (error.name === 'InvalidStateError') {
      message = 'Speech recognition is busy. Please try again.';
    } else {
      message = `Speech recognition error: ${error.message || 'Unknown error'}`;
    }
    
    showToast(message, 'error');
  }
  
  /**
   * Try to parse a date from speech input
   * @param {string} text - The speech text to parse
   * @returns {string|null} Date in YYYY-MM-DD format or null if not recognized
   */
  tryParseDateFromSpeech(text) {
    // Clean up the text
    const cleaned = text.toLowerCase().trim();
    
    // Check for "today", "tomorrow", "yesterday"
    const today = new Date();
    
    if (cleaned.includes('today')) {
      return this.formatDateForInput(today);
    } else if (cleaned.includes('tomorrow')) {
      const tomorrow = new Date();
      tomorrow.setDate(today.getDate() + 1);
      return this.formatDateForInput(tomorrow);
    } else if (cleaned.includes('yesterday')) {
      const yesterday = new Date();
      yesterday.setDate(today.getDate() - 1);
      return this.formatDateForInput(yesterday);
    }
    
    // Try to extract a date using Date.parse
    try {
      const parsedDate = new Date(cleaned);
      if (!isNaN(parsedDate.getTime())) {
        return this.formatDateForInput(parsedDate);
      }
    } catch (e) {
      console.log('Date parsing error:', e);
    }
    
    // Try with more advanced patterns
    const monthNames = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    
    // Pattern: "Month day year" or "Month day" (assumes current year)
    for (let i = 0; i < monthNames.length; i++) {
      if (cleaned.includes(monthNames[i])) {
        // Extract day and year
        const monthIndex = i;
        const parts = cleaned.split(' ');
        const monthPos = parts.findIndex(p => p.includes(monthNames[i]));
        
        if (monthPos >= 0 && monthPos < parts.length - 1) {
          // Look for day number after month
          const dayMatch = parts[monthPos + 1].match(/\d+/);
          if (dayMatch) {
            const day = parseInt(dayMatch[0], 10);
            
            // Look for year either after day or in the entire string
            let year = today.getFullYear();
            const yearMatch = cleaned.match(/\b(20\d{2})\b/); // Match years like 2021, 2022, etc.
            
            if (yearMatch) {
              year = parseInt(yearMatch[1], 10);
            }
            
            // Create and validate the date
            const date = new Date(year, monthIndex, day);
            if (!isNaN(date.getTime())) {
              return this.formatDateForInput(date);
            }
          }
        }
      }
    }
    
    return null;
  }
  
  /**
   * Format a Date object for a date input (YYYY-MM-DD)
   * @param {Date} date - The date to format
   * @returns {string} Formatted date string
   */
  formatDateForInput(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
  
  /**
   * Try to parse a time from speech input
   * @param {string} text - The speech text to parse
   * @returns {string|null} Time in HH:MM format or null if not recognized
   */
  tryParseTimeFromSpeech(text) {
    // Clean up the text
    const cleaned = text.toLowerCase().trim();
    
    // Match patterns like "3:30", "3:30 PM", "3 30 PM", "half past 3", etc.
    
    // Direct time format: "3:30" or "15:30"
    const timeRegex = /\b(\d{1,2})[:\s](\d{2})(?:\s*(am|pm))?\b/i;
    const timeMatch = cleaned.match(timeRegex);
    
    if (timeMatch) {
      let [_, hours, minutes, ampm] = timeMatch;
      hours = parseInt(hours, 10);
      minutes = parseInt(minutes, 10);
      
      // Adjust for AM/PM
      if (ampm && ampm.toLowerCase() === 'pm' && hours < 12) {
        hours += 12;
      } else if (ampm && ampm.toLowerCase() === 'am' && hours === 12) {
        hours = 0;
      }
      
      return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
    }
    
    // Try other common patterns
    if (cleaned.includes('noon')) {
      return '12:00';
    } else if (cleaned.includes('midnight')) {
      return '00:00';
    }
    
    // Hour only with AM/PM
    const hourRegex = /\b(\d{1,2})(?:\s*o'clock)?\s*(am|pm)\b/i;
    const hourMatch = cleaned.match(hourRegex);
    
    if (hourMatch) {
      let [_, hours, ampm] = hourMatch;
      hours = parseInt(hours, 10);
      
      // Adjust for AM/PM
      if (ampm.toLowerCase() === 'pm' && hours < 12) {
        hours += 12;
      } else if (ampm.toLowerCase() === 'am' && hours === 12) {
        hours = 0;
      }
      
      return `${String(hours).padStart(2, '0')}:00`;
    }
    
    // Handle "quarter past", "half past", etc.
    if (cleaned.includes('quarter past')) {
      const hourMatch = cleaned.match(/quarter past (\d{1,2})/);
      if (hourMatch) {
        let hour = parseInt(hourMatch[1], 10);
        if (cleaned.includes('pm') && hour < 12) hour += 12;
        return `${String(hour).padStart(2, '0')}:15`;
      }
    } else if (cleaned.includes('half past')) {
      const hourMatch = cleaned.match(/half past (\d{1,2})/);
      if (hourMatch) {
        let hour = parseInt(hourMatch[1], 10);
        if (cleaned.includes('pm') && hour < 12) hour += 12;
        return `${String(hour).padStart(2, '0')}:30`;
      }
    } else if (cleaned.includes('quarter to')) {
      const hourMatch = cleaned.match(/quarter to (\d{1,2})/);
      if (hourMatch) {
        let hour = parseInt(hourMatch[1], 10);
        if (cleaned.includes('pm') && hour < 12) hour += 12;
        if (hour > 1) hour -= 1;
        else hour = 23;  // Quarter to 1 means 12:45
        return `${String(hour).padStart(2, '0')}:45`;
      }
    }
    
    return null;
  }
  
  /**
   * Try to parse a number from speech input
   * @param {string} text - The speech text to parse
   * @returns {number|null} Parsed number or null if not recognized
   */
  tryParseNumberFromSpeech(text) {
    // Remove any non-numeric content except for decimal points and negatives
    const cleaned = text.toLowerCase().replace(/[^\d.-]/g, ' ').trim();
    
    // Match just the first number that appears
    const numberMatch = cleaned.match(/-?\d+(\.\d+)?/);
    
    if (numberMatch) {
      return parseFloat(numberMatch[0]);
    }
    
    // Try to parse number words
    const numberWords = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
      'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19, 'twenty': 20
    };
    
    // Check for simple number words
    for (const [word, value] of Object.entries(numberWords)) {
      if (text.toLowerCase().includes(word)) {
        return value;
      }
    }
    
    return null;
  }
  
  /**
   * Handle select dropdown inputs
   * @param {string} text - The speech text to use for selection
   */
  handleSelectInput(text) {
    if (!this.targetInput || this.targetInput.tagName.toLowerCase() !== 'select') return;
    
    // Clean up the spoken text
    const spokenText = text.toLowerCase().trim();
    let bestMatchOption = null;
    let bestMatchScore = 0;
    
    // Go through all options and find the best match
    for (let i = 0; i < this.targetInput.options.length; i++) {
      const option = this.targetInput.options[i];
      
      // Skip disabled options or placeholder options with empty values
      if (option.disabled || option.value === '') continue;
      
      const optionText = option.text.toLowerCase();
      const optionValue = option.value.toLowerCase();
      
      // Check for exact match in text or value
      if (spokenText === optionText || spokenText === optionValue) {
        bestMatchOption = option;
        break;
      }
      
      // Check if spoken text contains the option text
      if (spokenText.includes(optionText)) {
        const score = optionText.length / spokenText.length; // Longer matches relative to input are better
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatchOption = option;
        }
      }
      
      // Check if option text contains the spoken text
      if (optionText.includes(spokenText)) {
        const score = spokenText.length / optionText.length * 0.8; // Slightly lower priority
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatchOption = option;
        }
      }
    }
    
    // If we found a match, select it
    if (bestMatchOption) {
      this.targetInput.value = bestMatchOption.value;
      
      // Create and dispatch a change event
      const event = new Event('change', { bubbles: true });
      this.targetInput.dispatchEvent(event);
      
      // Show feedback
      const statusLabel = document.getElementById('speech-status-label');
      if (statusLabel) {
        statusLabel.innerHTML = `<i class="bi bi-check-circle text-success"></i> Selected: ${bestMatchOption.text}`;
      }
    }
  }
}

// Create and initialize the form speech input
document.addEventListener('DOMContentLoaded', () => {
  window.formSpeechInput = new FormSpeechInput();
  
  // Add styles for speech input
  const style = document.createElement('style');
  style.textContent = `
    .speech-active {
      border-color: #dc3545 !important;
      box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25) !important;
    }
    .speech-input-btn.active {
      color: #fff;
      background-color: #dc3545;
      border-color: #dc3545;
    }
  `;
  document.head.appendChild(style);
});

/**
 * Compatibility function for handling toast messages
 */
function showToast(message, type = 'info') {
  // Check if the showToast function is already defined elsewhere
  if (window.showToast && typeof window.showToast === 'function') {
    window.showToast(message, type);
    return;
  }
  
  // Create a basic toast implementation if not available
  const toastContainer = document.querySelector('.toast-container') || (() => {
    const container = document.createElement('div');
    container.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    document.body.appendChild(container);
    return container;
  })();
  
  const toast = document.createElement('div');
  toast.className = `toast align-items-center text-white bg-${type === 'error' ? 'danger' : type} border-0`;
  toast.setAttribute('role', 'alert');
  toast.setAttribute('aria-live', 'assertive');
  toast.setAttribute('aria-atomic', 'true');
  
  toast.innerHTML = `
    <div class="d-flex">
      <div class="toast-body">
        ${message}
      </div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
    </div>
  `;
  
  toastContainer.appendChild(toast);
  
  // Initialize and show the toast using Bootstrap
  if (window.bootstrap && bootstrap.Toast) {
    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();
  } else {
    // Fallback if Bootstrap JS is not loaded
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => {
        toast.remove();
      }, 300);
    }, 5000);
  }
}