/**
 * Form Speech Input
 * This module provides speech-to-text functionality for form inputs
 */

// Use a closure to avoid global namespace pollution
(function() {
  // Helper function for toast notifications
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
        if (this.targetInput) this.targetInput.classList.remove('speech-active');
      }
      
      /**
       * Handle recognition start event
       */
      handleRecognitionStart(event) {
        console.log('Speech recognition started');
        this.isListening = true;
      }
      
      /**
       * Handle recognition result event
       */
      handleRecognitionResult(event) {
        // Reset the inactivity timer on each result
        this.resetInactivityTimer();
        
        // Process the results
        let interimTranscript = '';
        
        for (let i = event.resultIndex; i < event.results.length; i++) {
          const transcript = event.results[i][0].transcript;
          
          if (event.results[i].isFinal) {
            this.finalTranscript += transcript;
          } else {
            interimTranscript += transcript;
          }
        }
        
        // Handle special content types based on the input
        if (this.targetInput) {
          // For date inputs, try to parse spoken dates
          if (this.targetInput.type === 'date') {
            const dateMatch = this.tryParseDateFromSpeech(this.finalTranscript || interimTranscript);
            if (dateMatch && event.results[event.resultIndex].isFinal) {
              this.targetInput.value = dateMatch;
              
              // Trigger change event for reactive frameworks
              const changeEvent = new Event('change', { bubbles: true });
              this.targetInput.dispatchEvent(changeEvent);
              
              // Stop listening since we found a date
              const inputGroup = this.targetInput.closest('.input-group');
              const micButton = inputGroup.querySelector('.speech-input-btn');
              const stopButton = inputGroup.querySelector('.speech-stop-btn');
              this.stopListening(micButton, stopButton);
              
              // Show confirmation toast
              showToast('Date recognized and entered', 'success');
              return;
            }
          }
          
          // For time inputs, try to parse spoken times
          else if (this.targetInput.type === 'time') {
            const timeMatch = this.tryParseTimeFromSpeech(this.finalTranscript || interimTranscript);
            if (timeMatch && event.results[event.resultIndex].isFinal) {
              this.targetInput.value = timeMatch;
              
              // Trigger change event for reactive frameworks
              const changeEvent = new Event('change', { bubbles: true });
              this.targetInput.dispatchEvent(changeEvent);
              
              // Stop listening since we found a time
              const inputGroup = this.targetInput.closest('.input-group');
              const micButton = inputGroup.querySelector('.speech-input-btn');
              const stopButton = inputGroup.querySelector('.speech-stop-btn');
              this.stopListening(micButton, stopButton);
              
              // Show confirmation toast
              showToast('Time recognized and entered', 'success');
              return;
            }
          }
          
          // For number inputs, try to parse spoken numbers
          else if (this.targetInput.type === 'number') {
            const numberMatch = this.tryParseNumberFromSpeech(this.finalTranscript || interimTranscript);
            if (numberMatch !== null && event.results[event.resultIndex].isFinal) {
              this.targetInput.value = numberMatch;
              
              // Trigger change event for reactive frameworks
              const changeEvent = new Event('change', { bubbles: true });
              this.targetInput.dispatchEvent(changeEvent);
              
              // Stop listening since we found a number
              const inputGroup = this.targetInput.closest('.input-group');
              const micButton = inputGroup.querySelector('.speech-input-btn');
              const stopButton = inputGroup.querySelector('.speech-stop-btn');
              this.stopListening(micButton, stopButton);
              
              // Show confirmation toast
              showToast('Number recognized and entered', 'success');
              return;
            }
          }
          
          // For select inputs, try to match options
          else if (this.targetInput.tagName.toLowerCase() === 'select' && event.results[event.resultIndex].isFinal) {
            this.handleSelectInput(this.finalTranscript || interimTranscript);
            return;
          }
          
          // For all other inputs, just set the value
          else {
            this.targetInput.value = this.finalTranscript + interimTranscript;
            
            // If this was a final result for regular text input, show a confirmation
            if (interimTranscript === '' && event.results[event.resultIndex].isFinal) {
              // Trigger change and input events for reactive frameworks
              const inputEvent = new Event('input', { bubbles: true });
              this.targetInput.dispatchEvent(inputEvent);
              
              const changeEvent = new Event('change', { bubbles: true });
              this.targetInput.dispatchEvent(changeEvent);
            }
          }
        }
      }
      
      /**
       * Handle recognition error event
       */
      handleRecognitionError(event) {
        console.error('Speech recognition error:', event.error);
        
        let errorMessage = 'Speech recognition error';
        
        switch (event.error) {
          case 'no-speech':
            errorMessage = 'No speech detected. Please try again.';
            break;
          case 'aborted':
            errorMessage = 'Speech input was aborted.';
            break;
          case 'audio-capture':
            errorMessage = 'Could not access microphone. Please check your settings.';
            break;
          case 'network':
            errorMessage = 'Network error occurred. Please check your connection.';
            break;
          case 'not-allowed':
            errorMessage = 'Microphone access not allowed. Please check permissions.';
            break;
          case 'service-not-allowed':
            errorMessage = 'Speech recognition service not allowed.';
            break;
          case 'bad-grammar':
            errorMessage = 'Grammar error in speech recognition.';
            break;
          case 'language-not-supported':
            errorMessage = 'Language not supported for speech recognition.';
            break;
        }
        
        this.showSpeechError(errorMessage);
        
        // Try to stop recognition and reset button state
        if (this.targetInput) {
          const inputGroup = this.targetInput.closest('.input-group');
          if (inputGroup) {
            const micButton = inputGroup.querySelector('.speech-input-btn');
            const stopButton = inputGroup.querySelector('.speech-stop-btn');
            if (micButton && stopButton) {
              this.stopListening(micButton, stopButton);
            }
          }
        }
      }
      
      /**
       * Handle recognition end event
       */
      handleRecognitionEnd(event) {
        console.log('Speech recognition ended');
        this.isListening = false;
        
        // If we're not in recovery mode, make sure UI is reset
        if (!this.inRecoveryMode && this.targetInput) {
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
        let message = typeof error === 'string' ? error : (error.message || 'Speech recognition error');
        showToast(message, 'error');
      }
      
      /**
       * Try to parse a date from speech input
       * @param {string} text - The speech text to parse
       * @returns {string|null} Date in YYYY-MM-DD format or null if not recognized
       */
      tryParseDateFromSpeech(text) {
        // Clean and normalize the text
        const cleanText = text.toLowerCase().trim();
        
        // Try to identify today, tomorrow, yesterday
        const now = new Date();
        
        if (cleanText.includes('today')) {
          return this.formatDateForInput(now);
        }
        
        if (cleanText.includes('tomorrow')) {
          const tomorrow = new Date(now);
          tomorrow.setDate(now.getDate() + 1);
          return this.formatDateForInput(tomorrow);
        }
        
        if (cleanText.includes('yesterday')) {
          const yesterday = new Date(now);
          yesterday.setDate(now.getDate() - 1);
          return this.formatDateForInput(yesterday);
        }
        
        // Try to match common date formats like "January 1 2023" or "1/1/2023"
        try {
          // Convert spoken month names to numerical values
          const monthMap = {
            january: '01', february: '02', march: '03', april: '04', may: '05', june: '06',
            july: '07', august: '08', september: '09', october: '10', november: '11', december: '12'
          };
          
          // Replace month names with their numerical equivalents
          let processedText = cleanText;
          for (const [month, num] of Object.entries(monthMap)) {
            if (cleanText.includes(month)) {
              processedText = processedText.replace(month, num);
              break;
            }
          }
          
          // Try to parse the date
          const dateObj = new Date(processedText);
          
          // Check if we got a valid date
          if (!isNaN(dateObj.getTime())) {
            return this.formatDateForInput(dateObj);
          }
        } catch (e) {
          console.warn('Date parsing error:', e);
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
        // Clean and normalize the text
        const cleanText = text.toLowerCase().trim();
        
        // Regular expression to match time patterns
        const timeRegex = /(\d{1,2})[:\s]?(\d{2})?\s*(am|pm)?/i;
        const match = cleanText.match(timeRegex);
        
        if (match) {
          let hours = parseInt(match[1], 10);
          const minutes = match[2] ? parseInt(match[2], 10) : 0;
          const ampm = match[3] ? match[3].toLowerCase() : null;
          
          // Handle AM/PM conversion
          if (ampm === 'pm' && hours < 12) {
            hours += 12;
          } else if (ampm === 'am' && hours === 12) {
            hours = 0;
          }
          
          // Format the time as HH:MM
          return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
        }
        
        // Try to handle special cases
        if (cleanText.includes('noon')) {
          return '12:00';
        }
        
        if (cleanText.includes('midnight')) {
          return '00:00';
        }
        
        return null;
      }
      
      /**
       * Try to parse a number from speech input
       * @param {string} text - The speech text to parse
       * @returns {number|null} Parsed number or null if not recognized
       */
      tryParseNumberFromSpeech(text) {
        // Clean and normalize the text
        const cleanText = text.toLowerCase().trim();
        
        // Word to number mapping for common number words
        const wordToNumber = {
          zero: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9,
          ten: 10, eleven: 11, twelve: 12, thirteen: 13, fourteen: 14, fifteen: 15, sixteen: 16,
          seventeen: 17, eighteen: 18, nineteen: 19, twenty: 20, thirty: 30, forty: 40, fifty: 50,
          sixty: 60, seventy: 70, eighty: 80, ninety: 90, hundred: 100, thousand: 1000, million: 1000000
        };
        
        // Try to match digits first
        const numberRegex = /[\-+]?\d+(\.\d+)?/g;
        const matches = cleanText.match(numberRegex);
        
        if (matches && matches.length > 0) {
          return parseFloat(matches[0]);
        }
        
        // If no digits found, try word numbers
        for (const [word, num] of Object.entries(wordToNumber)) {
          if (cleanText === word || cleanText.startsWith(word + ' ') || cleanText.endsWith(' ' + word) || cleanText.includes(' ' + word + ' ')) {
            return num;
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
        
        const options = Array.from(this.targetInput.options);
        let bestMatchIndex = -1;
        let bestMatchScore = 0;
        
        // Find option with best text match
        options.forEach((option, index) => {
          const similarity = this.calculateSimilarity(text, option.text);
          if (similarity > bestMatchScore) {
            bestMatchScore = similarity;
            bestMatchIndex = index;
          }
        });
        
        // If we found a decent match, select it
        if (bestMatchScore > 0.3 && bestMatchIndex !== -1) {
          this.targetInput.selectedIndex = bestMatchIndex;
          
          // Trigger change event
          const changeEvent = new Event('change', { bubbles: true });
          this.targetInput.dispatchEvent(changeEvent);
          
          // Show confirmation
          showToast(`Selected "${options[bestMatchIndex].text}"`, 'success');
          
          // Stop listening
          const inputGroup = this.targetInput.closest('.input-group');
          const micButton = inputGroup.querySelector('.speech-input-btn');
          const stopButton = inputGroup.querySelector('.speech-stop-btn');
          this.stopListening(micButton, stopButton);
        } else {
          // If no good match, provide feedback
          showToast(`Couldn't match "${text}" to any option`, 'warning');
          
          // Stop listening
          const inputGroup = this.targetInput.closest('.input-group');
          const micButton = inputGroup.querySelector('.speech-input-btn');
          const stopButton = inputGroup.querySelector('.speech-stop-btn');
          this.stopListening(micButton, stopButton);
        }
      }
      
      /**
       * Calculate text similarity (simple algorithm)
       * @param {string} str1 - First string
       * @param {string} str2 - Second string
       * @returns {number} Similarity score (0-1)
       */
      calculateSimilarity(str1, str2) {
        str1 = str1.toLowerCase();
        str2 = str2.toLowerCase();
        
        if (str1 === str2) return 1;
        
        // Simple character-based similarity for short strings
        const longer = str1.length > str2.length ? str1 : str2;
        const shorter = str1.length > str2.length ? str2 : str1;
        
        // Count of matching characters
        let matches = 0;
        for (let i = 0; i < shorter.length; i++) {
          if (longer.includes(shorter[i])) matches++;
        }
        
        return matches / longer.length;
      }
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
})();