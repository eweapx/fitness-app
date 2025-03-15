/**
 * Utility functions for the Health & Fitness Tracker
 */

/**
 * Generate a UUID for browser compatibility
 * This is a more compatible alternative to crypto.randomUUID()
 * @returns {string} UUID in standard format
 */
function generateUUID() {
  // Simple UUID generation that works in all browsers
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

/**
 * Format date as YYYY-MM-DD
 * @param {Date} date - Date to format
 * @returns {string} Formatted date
 */
function formatDateYYYYMMDD(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Format date as a readable string
 * @param {Date} date - Date to format
 * @returns {string} Formatted date
 */
function formatDateReadable(date) {
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

/**
 * Format time as HH:MM
 * @param {Date} date - Date to format
 * @returns {string} Formatted time
 */
function formatTimeHHMM(date) {
  return date.toLocaleTimeString(undefined, {
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Format a number with commas as thousands separators
 * @param {number} number - Number to format
 * @returns {string} Formatted number
 */
function formatNumberWithCommas(number) {
  return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/**
 * Create an element with classes and attributes
 * @param {string} tag - HTML tag name
 * @param {Object} options - Options for the element
 * @param {string|string[]} options.classes - CSS classes to add
 * @param {Object} options.attributes - HTML attributes to set
 * @param {string} options.textContent - Text content for the element
 * @param {string} options.innerHTML - HTML content for the element
 * @returns {HTMLElement} The created element
 */
function createElement(tag, options = {}) {
  const element = document.createElement(tag);
  
  // Add classes
  if (options.classes) {
    if (Array.isArray(options.classes)) {
      element.classList.add(...options.classes);
    } else {
      element.classList.add(options.classes);
    }
  }
  
  // Set attributes
  if (options.attributes) {
    for (const [key, value] of Object.entries(options.attributes)) {
      element.setAttribute(key, value);
    }
  }
  
  // Set text content
  if (options.textContent !== undefined) {
    element.textContent = options.textContent;
  }
  
  // Set HTML content
  if (options.innerHTML !== undefined) {
    element.innerHTML = options.innerHTML;
  }
  
  return element;
}

/**
 * Show a toast message to the user
 * @param {string} message - Message to display
 * @param {string} type - Type of message (success, error, warning, info)
 * @param {number} duration - Duration in milliseconds
 */
function showToast(message, type = 'info', duration = 3000) {
  // Create toast container if it doesn't exist
  let toastContainer = document.querySelector('.toast-container');
  if (!toastContainer) {
    toastContainer = createElement('div', {
      classes: 'toast-container position-fixed bottom-0 end-0 p-3'
    });
    document.body.appendChild(toastContainer);
  }
  
  // Create toast element
  const toastId = `toast-${generateUUID()}`;
  const toast = createElement('div', {
    classes: ['toast', `bg-${type}`],
    attributes: {
      'id': toastId,
      'role': 'alert',
      'aria-live': 'assertive',
      'aria-atomic': 'true'
    }
  });
  
  // Create toast body
  const toastBody = createElement('div', {
    classes: ['toast-body', type === 'light' ? 'text-dark' : 'text-white'],
    textContent: message
  });
  
  // Add close button
  const closeButton = createElement('button', {
    classes: 'btn-close btn-close-white me-2 m-auto',
    attributes: {
      'type': 'button',
      'data-bs-dismiss': 'toast',
      'aria-label': 'Close'
    }
  });
  
  const toastHeader = createElement('div', {
    classes: 'd-flex'
  });
  toastHeader.appendChild(toastBody);
  toastHeader.appendChild(closeButton);
  toast.appendChild(toastHeader);
  
  // Add to container
  toastContainer.appendChild(toast);
  
  // Initialize and show the toast
  const bsToast = new bootstrap.Toast(toast, {
    delay: duration,
    autohide: true
  });
  bsToast.show();
  
  // Remove the toast element when hidden
  toast.addEventListener('hidden.bs.toast', () => {
    toast.remove();
  });
}

/**
 * Debounce a function to limit how often it can be called
 * @param {Function} func - Function to debounce
 * @param {number} wait - Milliseconds to wait 
 * @returns {Function} Debounced function
 */
function debounce(func, wait = 300) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

/**
 * Throttle a function to limit how often it can be called
 * @param {Function} func - Function to throttle
 * @param {number} limit - Milliseconds to limit 
 * @returns {Function} Throttled function
 */
function throttle(func, limit = 300) {
  let inThrottle;
  return function executedFunction(...args) {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => {
        inThrottle = false;
      }, limit);
    }
  };
}

/**
 * Format a duration in seconds to a readable string
 * @param {number} seconds - Duration in seconds
 * @returns {string} Formatted duration string
 */
function formatDuration(seconds) {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = seconds % 60;
  
  if (hours > 0) {
    return `${hours}h ${minutes}m ${remainingSeconds}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${remainingSeconds}s`;
  } else {
    return `${remainingSeconds}s`;
  }
}

/**
 * Capitalize the first letter of each word in a string
 * @param {string} str - String to capitalize
 * @returns {string} Capitalized string
 */
function capitalizeWords(str) {
  return str
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

/**
 * Check if a date is today
 * @param {Date} date - Date to check
 * @returns {boolean} True if the date is today
 */
function isToday(date) {
  const today = new Date();
  return date.getDate() === today.getDate() &&
    date.getMonth() === today.getMonth() &&
    date.getFullYear() === today.getFullYear();
}

/**
 * Check if a date is yesterday
 * @param {Date} date - Date to check
 * @returns {boolean} True if the date is yesterday
 */
function isYesterday(date) {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  return date.getDate() === yesterday.getDate() &&
    date.getMonth() === yesterday.getMonth() &&
    date.getFullYear() === yesterday.getFullYear();
}

/**
 * Get a friendly relative date string
 * @param {Date} date - Date to format
 * @returns {string} Relative date string
 */
function getRelativeDateString(date) {
  if (isToday(date)) {
    return 'Today';
  } else if (isYesterday(date)) {
    return 'Yesterday';
  } else {
    return formatDateReadable(date);
  }
}