/**
 * Form Speech Input
 * This module provides speech-to-text functionality for form inputs
 */

// Use a closure to avoid global namespace pollution
(function() {

// Only define the class if it doesn't already exist in the window object
if (!window.FormSpeechInput) {
  window.FormSpeechInput = class FormSpeechInput {
    constructor() {
      this.isListening = false;
      this.targetInput = null;
      this.stopTimeout = null;
      this.inactivityTimeout = 5000; // Stop after 5 seconds of silence
      
      // Recovery state flags
      this.inRecoveryMode = false;
      this.recoveryAttempt = 0;
      this.lastRecoveryTime = 0;
      
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
          // Check if we already have a global instance we can reuse
          if (window.formSpeechRecognition && window.formSpeechRecognition.state !== 'active') {
            console.log('Reusing existing speech recognition instance');
            this.recognition = window.formSpeechRecognition;
            
            // Make sure the recognition object is in a clean state
            try {
              if (this.recognition.state === 'active') {
                this.recognition.stop();
              }
            } catch (e) {
              console.warn('Error stopping existing recognition:', e);
            }
          } else {
            // Create speech recognition instance
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            this.recognition = new SpeechRecognition();
            
            // Configure recognition for form input
            this.recognition.continuous = true;
            this.recognition.interimResults = true;
            this.recognition.lang = 'en-US';
            
            // Store globally for reuse
            window.formSpeechRecognition = this.recognition;
          }
          
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
      // Immediately add speech buttons to existing elements
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
      
      // Start observing the document with the configured parameters
      observer.observe(document.body, { childList: true, subtree: true });
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
        
        // Make sure we have a valid recognition object
        if (!this.recognition || this.recognition.onend === null) {
          console.warn('Recognition object is invalid or missing event handlers. Re-initializing...');
          this.initializeSpeechRecognition();
        }
        
        try {
          // Start recognition with a small delay to ensure it's ready
          setTimeout(() => {
            try {
              this.recognition.start();
              console.log('Started listening for form input');
              
              // Create a status label
              this.createStatusLabel(inputElement);
              
              // Set timeout to automatically stop after period of silence
              this.resetInactivityTimer();
            } catch (delayedError) {
              if (delayedError.name === 'InvalidStateError') {
                console.warn('InvalidStateError when starting recognition. Attempting recovery...');
                
                // Check if there's a global speechRecognizer instance we can use for recovery
                if (window.speechRecognizer && typeof window.speechRecognizer.handleStartError === 'function') {
                  console.log('Delegating InvalidStateError recovery to global speech recognizer');
                  
                  // Use the main speech recognizer's sophisticated recovery mechanism
                  window.speechRecognizer.handleStartError(delayedError);
                  
                  // Set a flag to indicate we're in recovery mode
                  this.inRecoveryMode = true;
                  
                  // Reset UI state after a delay
                  setTimeout(() => {
                    this.resetButtonState(micButton, stopButton);
                    this.inRecoveryMode = false;
                    
                    // Show a helpful message
                    const statusLabel = document.getElementById('speech-status-label');
                    if (statusLabel) {
                      statusLabel.className = 'form-text text-warning small mt-1 mb-2';
                      statusLabel.innerHTML = 'Speech recognition temporarily unavailable. Please try again in a moment.';
                      
                      // Remove the message after 3 seconds
                      setTimeout(() => {
                        if (statusLabel && statusLabel.parentNode) {
                          statusLabel.remove();
                        }
                      }, 3000);
                    }
                  }, 300);
                } else {
                  // Fallback to original recovery mechanism if global handler isn't available
                  console.warn('No global speech recognizer available for advanced recovery. Using basic recovery...');
                  
                  // Try to create a new recognition instance
                  this.initializeSpeechRecognition();
                
                  // Try one more time after a longer delay
                  setTimeout(() => {
                    try {
                      this.recognition.start();
                      console.log('Started listening for form input (second attempt)');
                    } catch (finalError) {
                      console.error('Still failed to start recognition:', finalError);
                      this.showSpeechError(finalError);
                      this.resetButtonState(micButton, stopButton);
                    }
                  }, 500); // Increased delay for better chance of recovery
                }
              } else {
                console.error('Error starting speech recognition after delay:', delayedError);
                this.showSpeechError(delayedError);
                this.resetButtonState(micButton, stopButton);
              }
            }
          }, 100);
        } catch (startError) {
          console.error('Error starting speech input:', startError);
          this.showSpeechError(startError);
          this.resetButtonState(micButton, stopButton);
        }
      } catch (error) {
        console.error('Error in startListeningForInput:', error);
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
      if (!this.isListening && !this.targetInput) return;
      
      try {
        // Stop the recognition if it exists
        if (this.recognition) {
          try {
            this.recognition.stop();
            console.log('Stopped listening for form input');
          } catch (stopError) {
            console.error('Error stopping recognition:', stopError);
            
            // If we got an InvalidStateError, the recognition may already be stopped
            if (stopError.name === 'InvalidStateError') {
              console.warn('Recognition was already stopped or in an invalid state');
            }
          }
        }
        
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
        
        // Always reset listening state
        this.isListening = false;
        
      } catch (error) {
        console.error('Error in stopListening:', error);
        // Make sure UI is reset even if there's an error
        this.isListening = false;
        if (micButton && stopButton) {
          this.resetButtonState(micButton, stopButton);
        }
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
      
      // Get current timestamp for error tracking
      const now = Date.now();
      const timeSinceLastRecovery = now - this.lastRecoveryTime;
      const maxRecoveryAttempts = 5; // Maximum consecutive recovery attempts
      const recoveryBackoff = [500, 1000, 2000, 3000, 5000]; // Exponential backoff in ms
      
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
      
      // If the error is InvalidStateError, attempt to recover
      if (event.error === 'not-allowed') {
        // This is a permission issue, no point in retrying
        this.speechEnabled = false;
        
        if (this.targetInput) {
          const inputGroup = this.targetInput.closest('.input-group');
          const micButton = inputGroup.querySelector('.speech-input-btn');
          const stopButton = inputGroup.querySelector('.speech-stop-btn');
          this.resetButtonState(micButton, stopButton);
        }
      } else if (this.recognitionEventsActive) {
        // For other errors, try to restart after a delay
        this.inRecoveryMode = true;
        this.lastRecoveryTime = now;
        
        // Only attempt recovery if we haven't exceeded our maximum tries or timeout
        if (this.recoveryAttempt < maxRecoveryAttempts && 
            timeSinceLastRecovery > 10000) { // At least 10 seconds since last recovery
          
          // Use exponential backoff to pace retry attempts
          const backoffTime = recoveryBackoff[Math.min(this.recoveryAttempt, recoveryBackoff.length - 1)];
          
          console.log(`Scheduling speech recognition recovery attempt ${this.recoveryAttempt + 1} in ${backoffTime}ms`);
          
          setTimeout(() => {
            try {
              if (this.recognition) {
                this.recognition.stop();
              }
              
              // Wait a moment before starting again
              setTimeout(() => {
                if (this.targetInput) {
                  // Still have an active target, so restart recognition
                  try {
                    this.recognition.start();
                    console.log(`Recognition restarted after recovery attempt ${this.recoveryAttempt + 1}`);
                    
                    if (statusLabel) {
                      statusLabel.className = 'form-text text-info small mt-1 mb-2';
                      statusLabel.innerHTML = '<i class="bi bi-mic-fill text-danger"></i> Listening... (recovered)';
                    }
                    
                    this.recoveryAttempt++;
                  } catch (recoveryErr) {
                    console.error('Failed to recover speech recognition:', recoveryErr);
                    
                    // If too many failures, reset the UI
                    if (this.recoveryAttempt >= maxRecoveryAttempts - 1) {
                      console.warn('Maximum recovery attempts reached. Stopping recognition.');
                      
                      if (this.targetInput) {
                        const inputGroup = this.targetInput.closest('.input-group');
                        const micButton = inputGroup.querySelector('.speech-input-btn');
                        const stopButton = inputGroup.querySelector('.speech-stop-btn');
                        this.resetButtonState(micButton, stopButton);
                      }
                    }
                  }
                } else {
                  // No active target, reset recovery mode
                  this.inRecoveryMode = false;
                }
              }, 200);
            } catch (e) {
              console.error('Error in recovery attempt:', e);
            }
          }, backoffTime);
        } else {
          console.warn('Recovery suppressed due to rate limit or max attempts');
          
          // Reset UI if we've hit the limit
          if (this.targetInput) {
            const inputGroup = this.targetInput.closest('.input-group');
            const micButton = inputGroup.querySelector('.speech-input-btn');
            const stopButton = inputGroup.querySelector('.speech-stop-btn');
            this.resetButtonState(micButton, stopButton);
          }
          
          this.inRecoveryMode = false;
        }
      }
    }
    
    /**
     * Handle recognition end event
     */
    handleRecognitionEnd(event) {
      console.log('Recognition ended for form input');
      this.isListening = false;
      
      // If we're in recovery mode, don't update the UI yet
      if (this.inRecoveryMode) {
        return;
      }
      
      // If we have a target input, update the buttons
      if (this.targetInput) {
        const inputGroup = this.targetInput.closest('.input-group');
        if (inputGroup) {
          const micButton = inputGroup.querySelector('.speech-input-btn');
          const stopButton = inputGroup.querySelector('.speech-stop-btn');
          
          if (micButton && stopButton) {
            this.resetButtonState(micButton, stopButton);
          }
        }
      }
    }
    
    /**
     * Show a speech error
     */
    showSpeechError(error) {
      let message = 'Speech recognition error';
      
      if (error.name === 'InvalidStateError') {
        message = 'Speech recognition is busy. Please try again in a moment.';
      } else if (error.name === 'NotAllowedError') {
        message = 'Microphone access denied. Please check your browser permissions.';
      } else if (error.message) {
        message = `Speech error: ${error.message}`;
      }
      
      console.error(message, error);
      
      // Show a toast message if the function exists
      if (typeof showToast === 'function') {
        showToast(message, 'error');
      }
    }
    
    /**
     * Try to parse a date from speech input
     * @param {string} text - The speech text to parse
     * @returns {string|null} Date in YYYY-MM-DD format or null if not recognized
     */
    tryParseDateFromSpeech(text) {
      // Common date patterns in speech
      const today = new Date();
      const todayPattern = /\b(today|now)\b/i;
      const tomorrowPattern = /\btomorrow\b/i;
      const yesterdayPattern = /\byesterday\b/i;
      
      // Format like "March 15th 2025" or "15th of March 2025"
      const datePattern = /\b(?:(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+(\d{1,2})(?:st|nd|rd|th)?|(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?)\s+(\d{4}|\d{2})\b/i;
      
      // Format like "mm/dd/yyyy" or "mm-dd-yyyy"
      const numericDatePattern = /\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4}|\d{2})\b/;
      
      if (todayPattern.test(text)) {
        return this.formatDateForInput(today);
      } else if (tomorrowPattern.test(text)) {
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        return this.formatDateForInput(tomorrow);
      } else if (yesterdayPattern.test(text)) {
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);
        return this.formatDateForInput(yesterday);
      } else if (datePattern.test(text)) {
        try {
          // Try to parse with Date.parse
          const date = new Date(text.replace(/(\d{1,2})(?:st|nd|rd|th)/g, '$1'));
          if (!isNaN(date.getTime())) {
            return this.formatDateForInput(date);
          }
        } catch (e) {
          console.warn('Error parsing date from speech:', e);
        }
      } else if (numericDatePattern.test(text)) {
        const match = text.match(numericDatePattern);
        try {
          // Assuming mm/dd/yyyy format
          const month = parseInt(match[1], 10) - 1; // 0-based month
          const day = parseInt(match[2], 10);
          let year = parseInt(match[3], 10);
          
          // Handle 2-digit years
          if (year < 100) {
            year += year < 50 ? 2000 : 1900;
          }
          
          const date = new Date(year, month, day);
          if (!isNaN(date.getTime())) {
            return this.formatDateForInput(date);
          }
        } catch (e) {
          console.warn('Error parsing numeric date from speech:', e);
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
      // Common time patterns in speech
      const timePattern = /\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b/i;
      
      // Special time patterns
      const noonPattern = /\bnoon\b/i;
      const midnightPattern = /\bmidnight\b/i;
      
      if (noonPattern.test(text)) {
        return '12:00';
      } else if (midnightPattern.test(text)) {
        return '00:00';
      } else if (timePattern.test(text)) {
        const match = text.match(timePattern);
        let hour = parseInt(match[1], 10);
        const minute = match[2] ? parseInt(match[2], 10) : 0;
        const period = match[3] ? match[3].toLowerCase() : null;
        
        // Adjust hour for 12-hour format if needed
        if (period === 'pm' && hour < 12) {
          hour += 12;
        } else if (period === 'am' && hour === 12) {
          hour = 0;
        }
        
        return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
      }
      
      return null;
    }
    
    /**
     * Try to parse a number from speech input
     * @param {string} text - The speech text to parse
     * @returns {number|null} Parsed number or null if not recognized
     */
    tryParseNumberFromSpeech(text) {
      // Match numbers - handle both digits and words
      const numberPattern = /\b(\d+(?:\.\d+)?)\b/;
      const match = text.match(numberPattern);
      
      if (match) {
        return parseFloat(match[1]);
      }
      
      // Try to convert word numbers to digits
      const wordToNumber = {
        zero: 0, one: 1, two: 2, three: 3, four: 4, five: 5,
        six: 6, seven: 7, eight: 8, nine: 9, ten: 10,
        eleven: 11, twelve: 12, thirteen: 13, fourteen: 14, fifteen: 15,
        sixteen: 16, seventeen: 17, eighteen: 18, nineteen: 19, twenty: 20
      };
      
      for (const [word, number] of Object.entries(wordToNumber)) {
        if (new RegExp(`\\b${word}\\b`, 'i').test(text)) {
          return number;
        }
      }
      
      return null;
    }
    
    /**
     * Handle select dropdown inputs
     * @param {string} text - The speech text to use for selection
     */
    handleSelectInput(text) {
      if (!this.targetInput || this.targetInput.tagName.toLowerCase() !== 'select') {
        return;
      }
      
      const options = Array.from(this.targetInput.options);
      let bestMatch = null;
      let bestMatchScore = 0;
      
      options.forEach(option => {
        // Skip empty or disabled options
        if (!option.value || option.disabled) {
          return;
        }
        
        // Calculate similarity with option text
        const similarity = this.calculateSimilarity(text.toLowerCase(), option.text.toLowerCase());
        if (similarity > bestMatchScore) {
          bestMatchScore = similarity;
          bestMatch = option;
        }
      });
      
      // If we found a reasonable match (>50% similarity), select it
      if (bestMatch && bestMatchScore > 0.5) {
        this.targetInput.value = bestMatch.value;
        
        // Show feedback
        const statusLabel = document.getElementById('speech-status-label');
        if (statusLabel) {
          statusLabel.innerHTML = `<i class="bi bi-check-circle text-success"></i> Selected: ${bestMatch.text}`;
        }
      }
    }
    
    /**
     * Calculate text similarity (simple algorithm)
     * @param {string} str1 - First string
     * @param {string} str2 - Second string
     * @returns {number} Similarity score (0-1)
     */
    calculateSimilarity(str1, str2) {
      // If either is empty, no match
      if (!str1 || !str2) return 0;
      
      // If exact match, perfect score
      if (str1 === str2) return 1;
      
      // If one contains the other completely, good score
      if (str1.includes(str2)) return 0.9;
      if (str2.includes(str1)) return 0.8;
      
      // Check for word-by-word match
      const words1 = str1.split(/\s+/);
      const words2 = str2.split(/\s+/);
      
      // Count matching words
      let matchCount = 0;
      for (const word1 of words1) {
        if (word1.length < 3) continue; // Skip very short words
        for (const word2 of words2) {
          if (word2.includes(word1) || word1.includes(word2)) {
            matchCount++;
            break;
          }
        }
      }
      
      // Calculate similarity based on matches
      return matchCount / Math.max(words1.length, words2.length);
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

// Initialize the speech input when the page loads
if (typeof window !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      console.log('Initializing FormSpeechInput instance');
      if (!window.formSpeechInput) {
        window.formSpeechInput = new window.FormSpeechInput();
      }
    });
  } else {
    // Document already loaded
    console.log('Document already loaded, initializing FormSpeechInput instance');
    if (!window.formSpeechInput) {
      window.formSpeechInput = new window.FormSpeechInput();
    }
  }
}

// Export the class for use in other modules if needed
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { FormSpeechInput: window.FormSpeechInput };
}