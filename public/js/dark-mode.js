/**
 * Dark Mode functionality for Health & Fitness Tracker
 * Handles theme switching and ensures modals get proper styling
 */

// Initialize dark mode based on user preference or system settings
document.addEventListener('DOMContentLoaded', function() {
  // Check for saved theme preference
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme) {
    document.body.setAttribute('data-theme', savedTheme);
    updateDarkModeButtonText(savedTheme === 'dark');
  } else {
    // Check for system preference
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      document.body.setAttribute('data-theme', 'dark');
      updateDarkModeButtonText(true);
    }
  }
  
  // Set up toggle button listener
  const darkModeToggle = document.getElementById('dark-mode-toggle');
  if (darkModeToggle) {
    darkModeToggle.addEventListener('click', toggleDarkMode);
  }
  
  // Apply dark mode to workout modals when they open
  setupModalDarkMode();
});

/**
 * Toggle between light and dark modes
 */
function toggleDarkMode() {
  const currentTheme = document.body.getAttribute('data-theme');
  const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
  
  document.body.setAttribute('data-theme', newTheme);
  localStorage.setItem('theme', newTheme);
  
  updateDarkModeButtonText(newTheme === 'dark');
  
  // If any modals are open, update their styling
  applyDarkModeToModals(newTheme === 'dark');
}

/**
 * Update the dark mode button text and icon
 * @param {boolean} isDark - Whether dark mode is active
 */
function updateDarkModeButtonText(isDark) {
  const darkModeToggle = document.getElementById('dark-mode-toggle');
  if (darkModeToggle) {
    if (isDark) {
      darkModeToggle.innerHTML = '<i class="bi bi-sun"></i> Light Mode';
      darkModeToggle.classList.replace('btn-outline-light', 'btn-outline-warning');
    } else {
      darkModeToggle.innerHTML = '<i class="bi bi-moon-stars"></i> Dark Mode';
      darkModeToggle.classList.replace('btn-outline-warning', 'btn-outline-light');
    }
  }
}

/**
 * Set up event listeners to ensure modals get dark mode styling
 */
function setupModalDarkMode() {
  // List of all modals in the app
  const modalIds = ['workoutModal', 'exerciseModal', 'activeWorkoutModal'];
  
  modalIds.forEach(id => {
    const modalElement = document.getElementById(id);
    if (modalElement) {
      // Apply dark mode when modal opens
      modalElement.addEventListener('show.bs.modal', function() {
        const isDark = document.body.getAttribute('data-theme') === 'dark';
        applyDarkModeToModal(this, isDark);
      });
    }
  });
}

/**
 * Apply dark mode styling to all modals
 * @param {boolean} isDark - Whether to apply dark mode
 */
function applyDarkModeToModals(isDark) {
  const modals = document.querySelectorAll('.modal');
  modals.forEach(modal => {
    applyDarkModeToModal(modal, isDark);
  });
}

/**
 * Apply dark mode styling to a specific modal
 * @param {HTMLElement} modal - The modal element
 * @param {boolean} isDark - Whether to apply dark mode
 */
function applyDarkModeToModal(modal, isDark) {
  if (!modal) return;
  
  // Modal content
  const content = modal.querySelector('.modal-content');
  if (content) {
    content.style.backgroundColor = isDark ? '#303030' : '';
    content.style.color = isDark ? '#fff' : '';
    content.style.borderColor = isDark ? '#444' : '';
  }
  
  // Modal header
  const header = modal.querySelector('.modal-header');
  if (header) {
    header.style.backgroundColor = isDark ? '#222' : '';
    header.style.borderColor = isDark ? '#444' : '';
    header.style.color = isDark ? '#fff' : '';
  }
  
  // Modal body
  const body = modal.querySelector('.modal-body');
  if (body) {
    body.style.backgroundColor = isDark ? '#303030' : '';
  }
  
  // Modal footer
  const footer = modal.querySelector('.modal-footer');
  if (footer) {
    footer.style.backgroundColor = isDark ? '#303030' : '';
    footer.style.borderColor = isDark ? '#444' : '';
  }
  
  // Form controls
  const inputs = modal.querySelectorAll('.form-control');
  inputs.forEach(input => {
    input.style.backgroundColor = isDark ? '#444' : '';
    input.style.color = isDark ? '#fff' : '';
    input.style.borderColor = isDark ? '#555' : '';
  });
  
  // Form labels
  const labels = modal.querySelectorAll('.form-label, .form-check-label');
  labels.forEach(label => {
    label.style.color = isDark ? '#fff' : '';
  });
  
  // Muted text
  const mutedText = modal.querySelectorAll('.text-muted');
  mutedText.forEach(text => {
    text.style.color = isDark ? '#adb5bd' : '';
  });
  
  // Set container and last weight indicator
  const setContainers = modal.querySelectorAll('.set-container');
  setContainers.forEach(container => {
    container.style.backgroundColor = isDark ? '#303030' : '';
  });
  
  const lastWeights = modal.querySelectorAll('.last-weight');
  lastWeights.forEach(lw => {
    lw.style.color = isDark ? '#adb5bd' : '';
  });
  
  // Dropdown menu
  const dropdowns = modal.querySelectorAll('.dropdown-menu');
  dropdowns.forEach(dropdown => {
    dropdown.style.backgroundColor = isDark ? '#303030' : '';
    dropdown.style.borderColor = isDark ? '#444' : '';
  });
  
  const dropdownItems = modal.querySelectorAll('.dropdown-item');
  dropdownItems.forEach(item => {
    item.style.color = isDark ? '#fff' : '';
  });
  
  // Close button
  const closeBtn = modal.querySelector('.btn-close');
  if (closeBtn) {
    closeBtn.style.filter = isDark ? 'invert(1) grayscale(100%) brightness(200%)' : '';
  }
}