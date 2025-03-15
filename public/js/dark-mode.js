/**
 * Dark Mode functionality for Health & Fitness Tracker
 */

// Execute when DOM is fully loaded
document.addEventListener('DOMContentLoaded', function() {
  // Initialize dark mode modal functionality
  setupModalDarkMode();
  
  // Update dark mode status based on data-theme attribute
  const currentTheme = document.documentElement.getAttribute('data-theme');
  if (currentTheme === 'dark') {
    document.body.classList.add('dark-mode');
    applyDarkModeToModals(true);
  }
  
  // Add event listener to the existing dark mode toggle button
  const darkModeToggle = document.getElementById('dark-mode-toggle');
  if (darkModeToggle) {
    // Add our additional dark mode functionality to the existing click handler
    darkModeToggle.addEventListener('click', function() {
      // Check if dark mode is active after the original click handler has run
      const isDarkMode = document.documentElement.getAttribute('data-theme') === 'dark';
      
      // Update body class for our CSS styling
      if (isDarkMode) {
        document.body.classList.add('dark-mode');
      } else {
        document.body.classList.remove('dark-mode');
      }
      
      // Apply dark mode to modals
      applyDarkModeToModals(isDarkMode);
    });
  }
}

/**
 * Set up event listeners to ensure modals get dark mode styling
 * @returns {void}
 */
function setupModalDarkMode() {
  // Apply dark mode to modals when they open
  document.addEventListener('shown.bs.modal', function(event) {
    if (document.body.classList.contains('dark-mode')) {
      applyDarkModeToModal(event.target, true);
    }
  });
  
  // Apply to all existing modals
  const isDarkMode = document.body.classList.contains('dark-mode');
  applyDarkModeToModals(isDarkMode);
  
  // Handle workout-specific modals and dynamically created elements
  const observer = new MutationObserver(function(mutations) {
    if (document.body.classList.contains('dark-mode')) {
      mutations.forEach(function(mutation) {
        if (mutation.addedNodes && mutation.addedNodes.length > 0) {
          mutation.addedNodes.forEach(function(node) {
            // Check if added node is a modal or contains modals
            if (node.classList && node.classList.contains('modal')) {
              applyDarkModeToModal(node, true);
            } else if (node.querySelectorAll) {
              const modals = node.querySelectorAll('.modal');
              modals.forEach(function(modal) {
                applyDarkModeToModal(modal, true);
              });
            }
          });
        }
      });
    }
  });
  
  // Observe the body for changes
  observer.observe(document.body, { childList: true, subtree: true });
}

/**
 * Apply dark mode styling to all modals
 * @param {boolean} isDark - Whether to apply dark mode
 * @returns {void}
 */
function applyDarkModeToModals(isDark) {
  const modals = document.querySelectorAll('.modal');
  modals.forEach(function(modal) {
    applyDarkModeToModal(modal, isDark);
  });
}

/**
 * Apply dark mode styling to a specific modal
 * @param {HTMLElement} modal - The modal element
 * @param {boolean} isDark - Whether to apply dark mode
 * @returns {void}
 */
function applyDarkModeToModal(modal, isDark) {
  if (!modal) return;
  
  // Get modal components
  const modalContent = modal.querySelector('.modal-content');
  const modalInputs = modal.querySelectorAll('input, select, textarea');
  const modalButtons = modal.querySelectorAll('.btn');
  
  if (isDark) {
    // Apply dark mode classes to modal elements
    if (modalContent) {
      modalContent.classList.add('bg-dark', 'text-white');
    }
    
    modalInputs.forEach(function(input) {
      input.classList.add('bg-dark', 'text-white', 'border-secondary');
    });
    
    // Special handling for exercise sets in workout modals
    const exerciseSets = modal.querySelectorAll('.exercise-set');
    exerciseSets.forEach(function(set) {
      set.classList.add('border-secondary');
      // Handle the "Last weight" label to ensure visibility
      const lastWeightLabel = set.querySelector('.last-weight');
      if (lastWeightLabel) {
        lastWeightLabel.classList.add('text-light');
      }
    });
    
    // Exercise sets in the form when adding/editing exercises 
    const setContainers = modal.querySelectorAll('.set-container');
    setContainers.forEach(function(container) {
      container.classList.add('border-secondary');
      // Make sure the last weight label is visible in dark mode
      const lastWeightLabel = container.querySelector('.last-weight');
      if (lastWeightLabel) {
        lastWeightLabel.classList.add('text-light');
      }
    });
  } else {
    // Remove dark mode classes
    if (modalContent) {
      modalContent.classList.remove('bg-dark', 'text-white');
    }
    
    modalInputs.forEach(function(input) {
      input.classList.remove('bg-dark', 'text-white', 'border-secondary');
    });
    
    // Remove dark mode classes from exercise sets
    const exerciseSets = modal.querySelectorAll('.exercise-set');
    exerciseSets.forEach(function(set) {
      set.classList.remove('border-secondary');
      const lastWeightLabel = set.querySelector('.last-weight');
      if (lastWeightLabel) {
        lastWeightLabel.classList.remove('text-light');
      }
    });
    
    // Remove dark mode from set containers
    const setContainers = modal.querySelectorAll('.set-container');
    setContainers.forEach(function(container) {
      container.classList.remove('border-secondary');
      const lastWeightLabel = container.querySelector('.last-weight');
      if (lastWeightLabel) {
        lastWeightLabel.classList.remove('text-light');
      }
    });
  }
}